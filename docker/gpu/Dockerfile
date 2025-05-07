FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

ARG TZ=PRC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-venv \
    git \
    curl \
    g++ \
    ca-certificates \
    # libsndfile1 if needed by deps during build
 && apt-get autoremove -y --purge \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Configure pip to use Tsinghua University mirror globally for this stage
RUN mkdir -p /root/.config/pip && \
    echo "[global]" > /root/.config/pip/pip.conf && \
    echo "index-url = https://pypi.tuna.tsinghua.edu.cn/simple/" >> /root/.config/pip/pip.conf && \
    echo "[install]" >> /root/.config/pip/pip.conf && \
    echo "trusted-host = pypi.tuna.tsinghua.edu.cn" >> /root/.config/pip/pip.conf

# Copy necessary project files for building from the build context root
COPY pyproject.toml ./pyproject.toml
COPY README.md ./README.md
COPY api ./api

# Create virtual environment
RUN python3.10 -m venv .venv

# Activate venv and upgrade pip, setuptools, wheel
RUN . .venv/bin/activate && \
    pip install -v --no-cache-dir --upgrade pip setuptools wheel

# Install project dependencies with verbose output and cache mount
RUN --mount=type=cache,target=/root/.cache/pip \
    . .venv/bin/activate && \
    pip install -v --no-cache-dir .[gpu]

FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

ARG TZ=PRC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-venv \
    espeak-ng \
    espeak-ng-data \
    libsndfile1 \
    ffmpeg \
    ca-certificates \
 && apt-get autoremove -y --purge \
 && apt-get clean && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /usr/share/espeak-ng-data \
 && ln -s /usr/lib/*/espeak-ng-data/* /usr/share/espeak-ng-data/

RUN useradd -m -u 1001 appuser
WORKDIR /app

# Copy the virtual environment from the builder stage
COPY --chown=appuser:appuser --from=builder /app/.venv ./.venv

# Copy project files for runtime
COPY api ./api
COPY web ./web
COPY docker/scripts/ ./docker/scripts
RUN chmod +x ./docker/scripts/entrypoint.sh

USER appuser

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app:/app/api \
    PATH="/app/.venv/bin:$PATH" \
    USE_GPU=true \
    PHONEMIZER_ESPEAK_PATH=/usr/bin \
    PHONEMIZER_ESPEAK_DATA=/usr/share/espeak-ng-data \
    ESPEAK_DATA_PATH=/usr/share/espeak-ng-data

ENV DOWNLOAD_MODEL=true
RUN mkdir -p api/src/models/v1_0 && \
    if [ "$DOWNLOAD_MODEL" = "true" ]; then \
    python docker/scripts/download_model.py --output api/src/models/v1_0; \
    fi

ENV DEVICE="gpu"
CMD ["./docker/scripts/entrypoint.sh"]
