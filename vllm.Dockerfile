FROM nvidia/cuda:13.0.2-devel-ubuntu24.04

# Install uv for faster builds
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Set non-interactive mode and bypass PEP 668 for system-wide installs
ENV DEBIAN_FRONTEND=noninteractive
ENV UV_BREAK_SYSTEM_PACKAGES=1

# Update and install Python 3 development headers and tools
# On Ubuntu 24.04, 'python3' is already version 3.12.
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3 as the default python
RUN ln -s /usr/bin/python3 /usr/bin/python || true

# Set environment variables for CUDA architecture compilation
# CUDA arch list used by torch/vLLM extensions - optimized for RTX 5090 and Blackwell
ENV TORCH_CUDA_ARCH_LIST='10.0+PTX 12.0+PTX 13.0+PTX'

# FlashAttention CUDA architectures - Blackwell support (compute capability 12.0)
ENV FLASH_ATTN_CUDA_ARCHS=130
ENV VLLM_FA_CMAKE_GPU_ARCHES='80-real;90-real;100-real;120-real'

# Build parallelization settings
ENV MAX_JOBS=2
ENV NVCC_THREADS=8

# Install vLLM with FlashInfer support for optimized attention
# Using uv for faster installation and --break-system-packages to install into system python
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages --pre \
    vllm --extra-index-url https://wheels.vllm.ai/nightly/cu129 \
    --extra-index-url https://download.pytorch.org/whl/cu129 \
    --index-strategy unsafe-best-match \
    transformers \
    accelerate

# Set environment variables for compilation and runtime
# These paths are critical for Blackwell Triton kernel compilation on WSL
ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs:/usr/local/cuda/compat:$LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/cuda/compat:$LD_LIBRARY_PATH

# Configure CUDA compat library
RUN ldconfig /usr/local/cuda-13/compat/ || true

# Set workplace
WORKDIR /app

# Expose the API port
EXPOSE 8000

# Entrypoint using python3 explicitly
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
