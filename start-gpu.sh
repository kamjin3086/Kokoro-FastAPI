#!/bin/bash

# Get project root directory
PROJECT_ROOT=$(pwd)

# Set environment variables
export USE_GPU=true
export USE_ONNX=false
export PYTHONPATH=$PROJECT_ROOT:$PROJECT_ROOT/api
export MODEL_DIR=src/models

# export VOICES_DIR=src/voices/v1_0
export VOICES_DIR=src/voices/v1_1-zh
export DEFAULT_VOICE=zf_094
export REPO_ID=hexgrad/Kokoro-82M-v1.1-zh

export WEB_PLAYER_PATH=$PROJECT_ROOT/web

# Run FastAPI with GPU extras using uv run
# Note: espeak may still require manual installation,
uv pip install -e ".[gpu]"
uv run --no-sync python docker/scripts/download_model.py --output api/src/models/v1_0
uv run --no-sync uvicorn api.src.main:app --host 0.0.0.0 --port 8880
