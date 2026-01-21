# Use NVIDIA CUDA 12.6.3 Devel on Ubuntu 24.04 (Python 3.12 is native)
FROM nvidia/cuda:12.6.3-devel-ubuntu24.04

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

# Upgrade pip and install vLLM
# Note: Ubuntu 24.04 requires --break-system-packages for pip install in system context 
# unless using a virtual environment. For a container, this flag is acceptable.
RUN python3 -m pip install --upgrade pip --break-system-packages \
    && pip install vllm>=0.6.6 --break-system-packages

# Set environment variables for compilation and runtime
# These paths are critical for Blackwell Triton kernel compilation on WSL
ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs:/usr/local/cuda/compat:$LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/cuda/compat:$LD_LIBRARY_PATH

# Set workplace
WORKDIR /app

# Expose the API port
EXPOSE 8000

# Entrypoint using python3 explicitly
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
