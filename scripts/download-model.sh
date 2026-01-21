#!/bin/bash
# ==============================================
# SOLV Stack - Model Download Script
# Download models from Hugging Face to local storage
# ==============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default model
DEFAULT_MODEL="Qwen/Qwen3-Coder-30B-A3B-Instruct"
DEFAULT_LOCAL_DIR="./models/Qwen3-Coder-30B-A3B-Instruct"

# Parse arguments
MODEL_NAME="${1:-$DEFAULT_MODEL}"
LOCAL_DIR="${2:-$DEFAULT_LOCAL_DIR}"

echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     SOLV Stack - Model Downloader          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if hf CLI is installed
if ! command -v hf &> /dev/null; then
    echo -e "${YELLOW}Installing huggingface-hub CLI...${NC}"
    pip install -U huggingface_hub[cli]
fi

# Check HF token
if [ -z "$HF_TOKEN" ]; then
    echo -e "${YELLOW}Note: HF_TOKEN not set. Some gated models may require authentication.${NC}"
    echo -e "${YELLOW}Run: hf login${NC}"
    echo ""
fi

echo -e "${GREEN}Downloading model:${NC} $MODEL_NAME"
echo -e "${GREEN}Target directory:${NC} $LOCAL_DIR"
echo ""

# Create target directory
mkdir -p "$(dirname "$LOCAL_DIR")"

# Download model using hf CLI
hf download "$MODEL_NAME" --local-dir "$LOCAL_DIR"

echo ""
echo -e "${GREEN}✅ Download complete!${NC}"
echo -e "Model saved to: $LOCAL_DIR"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update .env with: VLLM_MODEL=$(basename $LOCAL_DIR)"
echo "2. Run: docker compose up -d"
