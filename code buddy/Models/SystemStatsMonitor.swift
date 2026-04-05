//
//  SystemStatsMonitor.swift
//  code buddy
//
//  Reads real system stats via Mach / Darwin low-level APIs.
//

import Foundation
import Darwin

final class SystemStatsMonitor: ObservableObject {

    // MARK: - Published values
    @Published var memoryUsedGB: Double = 0       // physical RAM in use (GB)
    @Published var memoryTotalGB: Double = 0      // total physical RAM (GB)
    @Published var memoryFraction: Double = 0     // 0-1 for progress bar

    @Published var cpuUsageFraction: Double = 0   // 0-1 aggregate CPU load
    @Published var cpuPercent: Double = 0         // 0-100

    @Published var diskUsedGB: Double = 0
    @Published var diskTotalGB: Double = 0
    @Published var diskFraction: Double = 0

    // MARK: - Private
    private var timer: Timer?
    private var prevCPUInfo: processor_info_array_t?
    private var prevCPUInfoCount: mach_msg_type_number_t = 0

    // MARK: - Lifecycle
    func start(interval: TimeInterval = 2.0) {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Refresh
    private func refresh() {
        let mem = readMemory()
        let cpu = readCPU()
        let disk = readDisk()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.memoryUsedGB   = mem.used
            self.memoryTotalGB  = mem.total
            self.memoryFraction = mem.total > 0 ? min(mem.used / mem.total, 1.0) : 0

            self.cpuUsageFraction = cpu
            self.cpuPercent       = cpu * 100

            self.diskUsedGB   = disk.used
            self.diskTotalGB  = disk.total
            self.diskFraction = disk.total > 0 ? min(disk.used / disk.total, 1.0) : 0
        }
    }

    // MARK: - Memory (Mach vm_statistics64)
    private func readMemory() -> (used: Double, total: Double) {
        // Total physical RAM via sysctl
        var size = MemoryLayout<UInt64>.size
        var totalBytes: UInt64 = 0
        sysctlbyname("hw.memsize", &totalBytes, &size, nil, 0)
        let totalGB = Double(totalBytes) / 1_073_741_824

        // Used = active + wired (pages in use by processes / kernel)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let host = mach_host_self()
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return (0, totalGB) }

        let pageSize = Double(vm_kernel_page_size)
        let active  = Double(stats.active_count)   * pageSize
        let wired   = Double(stats.wire_count)     * pageSize
        let usedGB  = (active + wired) / 1_073_741_824

        return (usedGB, totalGB)
    }

    // MARK: - CPU (host_processor_info per-core ticks delta)
    private func readCPU() -> Double {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let kr = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &cpuInfoCount
        )
        guard kr == KERN_SUCCESS, let info = cpuInfo else { return 0 }
        // Note: no defer dealloc here — we store cpuInfo in prevCPUInfo and free it next cycle

        var totalUser: Int32 = 0
        var totalSystem: Int32 = 0
        var totalIdle: Int32 = 0
        var totalNice: Int32 = 0

        let stride = Int(CPU_STATE_MAX)
        for i in 0 ..< Int(numCPUs) {
            totalUser   += info[i * stride + Int(CPU_STATE_USER)]
            totalSystem += info[i * stride + Int(CPU_STATE_SYSTEM)]
            totalIdle   += info[i * stride + Int(CPU_STATE_IDLE)]
            totalNice   += info[i * stride + Int(CPU_STATE_NICE)]
        }

        // Delta against previous sample
        var userDelta: Int32 = totalUser
        var systemDelta: Int32 = totalSystem
        var idleDelta: Int32 = totalIdle
        var niceDelta: Int32 = totalNice

        // Capture old buffer info before overwriting
        let oldInfo      = prevCPUInfo
        let oldInfoCount = prevCPUInfoCount

        if let prev = oldInfo {
            for i in 0 ..< Int(numCPUs) {
                userDelta   -= prev[i * stride + Int(CPU_STATE_USER)]
                systemDelta -= prev[i * stride + Int(CPU_STATE_SYSTEM)]
                idleDelta   -= prev[i * stride + Int(CPU_STATE_IDLE)]
                niceDelta   -= prev[i * stride + Int(CPU_STATE_NICE)]
            }
        }

        // Store new buffer first, then free the old one
        prevCPUInfo      = cpuInfo
        prevCPUInfoCount = cpuInfoCount

        if let prev = oldInfo {
            vm_deallocate(mach_task_self_,
                          vm_address_t(bitPattern: prev),
                          vm_size_t(oldInfoCount) * vm_size_t(MemoryLayout<integer_t>.size))
        }

        let total = Double(userDelta + systemDelta + idleDelta + niceDelta)
        guard total > 0 else { return 0 }
        let busy = Double(userDelta + systemDelta + niceDelta)
        return min(busy / total, 1.0)
    }

    // MARK: - Disk (FileManager / statvfs on /)
    private func readDisk() -> (used: Double, total: Double) {
        var stat = statvfs()
        guard statvfs("/", &stat) == 0 else { return (0, 0) }
        let blockSize  = Double(stat.f_frsize)
        let totalBytes = Double(stat.f_blocks) * blockSize
        let freeBytes  = Double(stat.f_bfree)  * blockSize
        let usedBytes  = totalBytes - freeBytes
        let gb: Double = 1_073_741_824
        return (usedBytes / gb, totalBytes / gb)
    }
}
