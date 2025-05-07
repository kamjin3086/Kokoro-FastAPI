FROM python:3.10-slim AS builder

# Set Timezone, update APT sources, install build-time system dependencies
ARG TZ=PRC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    # curl is no longer needed for uv install, keep if other scripts use it, else remove \
    # g++ is needed for some python package builds \
    g++ \
    ca-certificates \
    # python3.10-venv is not needed for python:3.10-slim as venv is standard lib \
    # libsndfile1 might be needed if some deps link to it during build, otherwise can move to final \
 && apt-get autoremove -y --purge \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

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
# Add other necessary files/dirs if your setup process requires them, e.g.:
# COPY web ./web
# COPY docker ./docker # If scripts from docker/scripts are needed during build, adjust path accordingly

# Install Rust (required to build sudachipy and pyopenjtalk-plus)
# User is root in this stage
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Create virtual environment
RUN python3.10 -m venv .venv

# Activate venv and upgrade pip, setuptools, wheel
RUN . .venv/bin/activate && \
    pip install -v --no-cache-dir --upgrade pip setuptools wheel

# Install project dependencies with verbose output and cache mount
RUN --mount=type=cache,target=/root/.cache/pip \
    . .venv/bin/activate && \
    pip install -v --no-cache-dir .[cpu]

FROM python:3.10-slim

# Set Timezone, update APT sources, install runtime system dependencies
ARG TZ=PRC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

RUN apt-get update && apt-get install -y --no-install-recommends \
    espeak-ng \
    espeak-ng-data \
    libsndfile1 \
    ffmpeg \
    ca-certificates \
    # python3.10-venv is not needed here either \
 && apt-get autoremove -y --purge \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /usr/share/espeak-ng-data \
 && ln -s /usr/lib/*/espeak-ng-data/* /usr/share/espeak-ng-data/

# Create non-root user and set up directories
RUN useradd -m -u 1000 appuser
WORKDIR /app

# Copy the virtual environment from the builder stage
COPY --chown=appuser:appuser --from=builder /app/.venv ./.venv

# Copy project files for runtime (these paths are relative to WORKDIR /app in final stage, a bit different from builder)
COPY api ./api
COPY web ./web
COPY docker/scripts/ ./docker/scripts
RUN chmod +x ./docker/scripts/entrypoint.sh

USER appuser

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app:/app/api \
    PATH="/app/.venv/bin:$PATH" \
    USE_GPU=false \
    PHONEMIZER_ESPEAK_PATH=/usr/bin \
    PHONEMIZER_ESPEAK_DATA=/usr/share/espeak-ng-data \
    ESPEAK_DATA_PATH=/usr/share/espeak-ng-data

ENV DOWNLOAD_MODEL=true
RUN mkdir -p api/src/models/v1_0 && \
    if [ "$DOWNLOAD_MODEL" = "true" ]; then \
    python docker/scripts/download_model.py --output api/src/models/v1_0; \
    fi

ENV DEVICE="cpu"
CMD ["./docker/scripts/entrypoint.sh"]
