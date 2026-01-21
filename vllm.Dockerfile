# Use NVIDIA CUDA 12.6 Devel image as base (contains nvcc and development headers)
FROM nvidia/cuda:13.0.0-devel-ubuntu22.04

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Python 3.12, development headers, and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3.12-distutils \
    python3-pip \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.12 as the default python
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && update-alternatives --set python3 /usr/bin/python3.12 \
    && ln -s /usr/bin/python3 /usr/bin/python

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Install vLLM (Choosing a version that has better Blackwell support)
# We use vLLM >= 0.6.6 which includes more Blackwell-related fixes
RUN pip install vllm>=0.6.6

# Set environment variables for compilation and runtime
# Using stubs and compat paths to ensure -lcuda works during Triton kernel compilation
ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs:/usr/local/cuda/compat:$LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/cuda/compat:$LD_LIBRARY_PATH

# Set workplace
WORKDIR /app

# Expose the API port
EXPOSE 8000

# The entrypoint mimicking the official vllm-openai image
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
