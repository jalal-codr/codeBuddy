# CodeBud

A local AI coding assistant for macOS. Everything runs on your machine — no cloud, no data leaving your computer.

Built with SwiftUI and powered by [Ollama](https://ollama.com).

---

## Requirements

- macOS 12.7+
- [Ollama](https://ollama.com) installed
- At least one language model pulled (e.g. `llama3`, `qwen2.5-coder:3b`)
- `nomic-embed-text` model for codebase indexing

---

## Getting Started

**1. Install Ollama**

Download from [ollama.com](https://ollama.com). CodeBud starts it automatically on launch.

**2. Install models**

Open the **Models** tab → **Model Store** and install at least one chat model. If you want to use RAG mode, also install `nomic-embed-text`.

Or pull from the terminal:
```bash
ollama pull llama3
ollama pull nomic-embed-text
```

**3. Build and run**

Open `code buddy.xcodeproj` in Xcode and hit Run.

---

## Features

### Chat (Setup tab)

Two modes, automatically selected:

| Mode | When | How |
|------|------|-----|
| **Direct Chat** | No folder indexed | Sends your message straight to the model |
| **RAG Mode** | After indexing a folder | Retrieves relevant code chunks, builds context, then queries the model |

- Stop a running generation with the **■** button
- Edit any sent message with the **pencil** button — removes it and its response, puts the text back in the input
- Copy any AI response with the **Copy** button

### Codebase Indexing

1. Click **Browse** and select your project folder
2. Click **Confirm** — CodeBud walks the directory, chunks every file into 30-line segments, embeds each chunk via `nomic-embed-text`, and stores vectors in memory
3. The mode badge switches to **RAG MODE** — questions are now answered with your code as context

### Models tab

- Lists all models installed on your system via the Ollama API
- **Filter** by model family
- **Refresh** to sync with Ollama
- **Model Store** — browse and install curated models with a live progress bar
- **Change Model** dropdown on the active card — switch instantly
- **Model Settings** popover — adjust temperature and context length
- Delete any model with the trash icon

### Settings tab

- Set your **display name** — shown in the sidebar and used by the model to address you
- **Active model** selector — same as the sidebar picker and Models tab, all in sync

### Sidebar

- Quick **model switcher** dropdown always visible
- **Docs** — in-app documentation sheet
- **Donate** — opens [buymeacoffee.com/jallall](https://buymeacoffee.com/jallall)

---

## How RAG Works

```
Select folder → chunk files (30 lines each) → embed via nomic-embed-text
                                                        ↓
Ask question → embed question → cosine similarity → top 3 chunks
                                                        ↓
                              build prompt with context → send to model
```

The index lives in memory and is cleared when you quit. Re-index after significant changes to your codebase.

---

## Adaptive Theme

CodeBud follows your macOS system appearance automatically — light mode gets a clean white/blue palette, dark mode uses the original dark theme. Change it in **System Settings → Appearance**.

---

## Project Structure

```
code buddy/
├── Models/
│   ├── BackendManager.swift      # RAG engine + Ollama API calls
│   ├── OllamaManager.swift       # ollama serve lifecycle
│   ├── OllamaModelManager.swift  # model list, pull, delete
│   ├── SystemStatsMonitor.swift  # live CPU/RAM/disk stats
│   └── ChatMessage.swift
├── Views/
│   ├── SetupView.swift           # chat + folder picker
│   ├── ModelsView.swift          # model management
│   ├── SettingsView.swift
│   ├── ModelStoreSheet.swift
│   ├── DocsSheet.swift
│   └── Components/
├── Sidebar/SidebarView.swift
├── Theme.swift                   # adaptive light/dark colors
└── ContentView.swift
```

---

## License

MIT
