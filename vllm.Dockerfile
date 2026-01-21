# Use NVIDIA CUDA 12.8.0 Devel on Ubuntu 24.04 (Python 3.12 is native)
FROM nvidia/cuda:12.9.0-devel-ubuntu24.04

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Python 3 development headers and tools
# On Ubuntu 24.04, 'python3' is already version 3.12.
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3 as the default python
RUN ln -s /usr/bin/python3 /usr/bin/python || true

# Set environment variables for CUDA architecture compilation
# CUDA arch list used by torch/vLLM extensions - optimized for RTX 5090 and Blackwell
ENV TORCH_CUDA_ARCH_LIST='10.0+PTX 12.0+PTX'

# FlashAttention CUDA architectures - Blackwell support (compute capability 12.0)
ENV FLASH_ATTN_CUDA_ARCHS=120
ENV VLLM_FA_CMAKE_GPU_ARCHES='80-real;90-real;100-real'

# Build parallelization settings
ENV MAX_JOBS=2
ENV NVCC_THREADS=8

# Install vLLM with FlashInfer support for optimized attention
# Note: Ubuntu 24.04 requires --break-system-packages for pip install in system context 
# unless using a virtual environment. For a container, this flag is acceptable.
RUN pip install --upgrade pip --break-system-packages || true
RUN pip install 'vllm[flashinfer]>=0.6.6' --break-system-packages

# Set environment variables for compilation and runtime
# These paths are critical for Blackwell Triton kernel compilation on WSL
ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs:/usr/local/cuda/compat:$LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/cuda/compat:$LD_LIBRARY_PATH

# Configure CUDA compat library
RUN ldconfig /usr/local/cuda-12/compat/ || true

# Set workplace
WORKDIR /app

# Expose the API port
EXPOSE 8000

# Entrypoint using python3 explicitly
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
