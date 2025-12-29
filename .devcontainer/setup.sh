#!/bin/bash
set -e

echo "Installing mise..."
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

echo "Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code

echo "Setup complete!"
echo "Run 'source ~/.bashrc' or open a new terminal to use mise."
echo "Run 'claude' to start Claude Code."
