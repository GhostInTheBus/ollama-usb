# ollama-usb

A portable, self-contained AI chatbot that runs from a USB drive on macOS. Plug in, double-click, chat — no installation required on the target machine.

https://github.com/user-attachments/assets/311876fd-ead2-44b9-80ab-a5fb7b95511a

[Watch on YouTube](https://youtu.be/z4MM0MGhCp4) (1:23)

## What it is

- Local LLM inference from a USB stick — no internet, no cloud, no data leaves the machine
- Works on any Mac that has Ollama installed
- Clean browser-based chat UI with multi-model support and streaming responses
- One double-click to launch, Ctrl+C to shut down

## Requirements

- macOS (Apple Silicon or Intel)
- [Ollama](https://ollama.com) installed on the machine you use for setup
- USB 3.0 drive (minimum size depends on models — ~10GB for small models, 32GB+ for larger ones)

## Setup

Run this once on your own Mac to prepare the USB drive.

**1. Clone this repo directly onto your USB drive:**
```bash
git clone https://github.com/GhostInTheBus/ollama-usb /Volumes/YOUR-USB-NAME
```

**2. Run the setup script:**
```bash
cd /Volumes/YOUR-USB-NAME
bash setup.sh
```

The setup script will:
- Copy the Ollama binary from your local installation
- Show you a list of your installed models
- Let you choose which ones to copy to the USB

**3. Eject and go.**

## Usage

1. Plug the USB into any Mac
2. Open the USB in Finder
3. Double-click **`launch.command`**
4. A browser window opens at `http://localhost:8765` with the chat interface
5. Select a model from the dropdown and start chatting
6. Press `Ctrl+C` in the Terminal window to shut down

> **First run on a new Mac:** macOS may block the `ollama` binary with a Gatekeeper warning. Right-click the `ollama` file → **Open** → click **Open** in the dialog. Then re-run `launch.command`.

## How it works

```
USB Drive
├── ollama              macOS binary (copied from your Ollama.app)
├── launch.command      startup script
├── setup.sh            one-time setup script
├── models/             model files (not tracked in git)
│   ├── blobs/          content-addressed model weights
│   └── manifests/      model metadata
└── ui/
    └── chat.html       single-file chat interface
```

**Launch flow:**
1. `launch.command` sets `OLLAMA_MODELS` to the USB models folder and `OLLAMA_HOST` to port `11435` (avoids conflict with any locally running Ollama instance)
2. Starts `ollama serve` in the background
3. Serves `chat.html` via Python's built-in HTTP server on port `8765` (required to avoid browser CORS restrictions on `file://` URLs)
4. Opens the browser

## Recommended models

| Model | Size | Good for |
|---|---|---|
| `mistral:instruct` | ~4GB | General Q&A, fast |
| `llama3.1:8b` | ~5GB | General chat, instruction following |
| `llama3.2:3b` | ~2GB | Tight on space, still capable |
| `qwen2.5:7b` | ~5GB | Strong reasoning |

Pull models with `ollama pull <model>` before running setup.

## Limitations

- **macOS only** — the included binary is macOS-specific. Linux and Windows support would require separate binaries and launchers.
- **No autorun** — macOS (and all modern OSes) block USB autorun for security reasons. One double-click is the minimum.
- **Ollama must be installed** on the machine you run setup on (to get the binary and models). The target machine does not need Ollama installed.
- **RAM** — model inference happens in the host machine's RAM. A 7B model needs ~8GB free RAM; a 30B model needs ~20GB.

## License

MIT
