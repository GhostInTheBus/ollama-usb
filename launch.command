#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==============================="
echo "  Ollama USB Launcher"
echo "==============================="
echo "USB path: $DIR"
echo ""

# Strip quarantine flag so macOS doesn't block the binary
xattr -d com.apple.quarantine "$DIR/ollama" 2>/dev/null

# Kill any leftover USB server from a previous session
pkill -f "http.server 8765" 2>/dev/null
lsof -i :11435 -t | xargs kill 2>/dev/null
sleep 1

# Point ollama at the USB models, run on port 11435 (avoids conflict with local Ollama.app)
export OLLAMA_MODELS="$DIR/models"
export OLLAMA_HOST="127.0.0.1:11435"
export OLLAMA_ORIGINS="http://localhost:8765"
echo "Models: $OLLAMA_MODELS"
echo ""

# Start the ollama server
echo "Starting Ollama server..."
"$DIR/ollama" serve > /tmp/ollama-usb.log 2>&1 &
OLLAMA_PID=$!

# Wait for ollama to be ready (up to 30s)
echo -n "Waiting for Ollama"
READY=0
for i in {1..120}; do
  if curl -s http://localhost:11435/api/tags > /dev/null 2>&1; then
    echo " ready!"
    READY=1
    break
  fi
  echo -n "."
  sleep 1
done

if [ $READY -eq 0 ]; then
  echo ""
  echo "ERROR: Ollama failed to start after 2 minutes."
  echo ""
  echo "--- Ollama log ---"
  cat /tmp/ollama-usb.log
  echo ""
  echo "If you see a Gatekeeper error, right-click the 'ollama' file → Open → trust it, then re-run launch.command."
  read -p "Press Enter to exit..."
  exit 1
fi

# Start a simple HTTP server to serve the chat UI (avoids browser CORS block)
echo "Starting UI server..."
cd "$DIR/ui" && python3 -m http.server 8765 > /dev/null 2>&1 &
PYTHON_PID=$!
sleep 1

# Open the chat UI over HTTP
echo "Opening chat at http://localhost:8765/chat.html ..."
open "http://localhost:8765/chat.html"

echo ""
echo "Chat is open. Keep this window open — closing it stops everything."
echo "Press Ctrl+C to shut down."
echo ""

cleanup() {
  echo ""
  echo "Shutting down..."
  kill $OLLAMA_PID 2>/dev/null
  kill $PYTHON_PID 2>/dev/null
  exit 0
}
trap cleanup INT TERM

wait $OLLAMA_PID
