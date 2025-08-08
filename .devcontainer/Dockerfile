# GoodMem DevContainer - Clean version with only SDKs and runtime environments
FROM ubuntu:24.04

LABEL org.opencontainers.image.title="GoodMem Dev Environment" \
      org.opencontainers.image.description="Minimal SDK setup for developing with GoodMem APIs" \
      org.opencontainers.image.version="1.0.0"

SHELL ["/bin/bash", "-c"]

# System utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git unzip gnupg ca-certificates software-properties-common \
    build-essential apt-transport-https sudo \
    python3 python3-venv python3-pip python3-dev \
    libffi-dev libssl-dev libpq-dev cargo \
    && rm -rf /var/lib/apt/lists/*

# Use python3 as "python"
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Python SDK + OpenAI (with Python 3.12 PEP 668 override)
RUN pip install goodmem_client openai requests python-dotenv --break-system-packages


# Java 17 (for GoodMem Java client)
RUN apt-get update && apt-get install -y openjdk-17-jdk && \
    rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# .NET 8 SDK
RUN wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb && \
    apt-get update && apt-get install -y dotnet-sdk-8.0 && \
    rm -rf /var/lib/apt/lists/*
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="$DOTNET_ROOT:$PATH"

# Go 1.22
RUN wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz && rm go1.22.2.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:$PATH"

# Node.js + GoodMem JS SDK
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g @pairsystems/goodmem-client && \
    rm -rf /var/lib/apt/lists/*


    # Install GoodMem CLI (linux-amd64)
RUN curl -L -o /usr/local/bin/goodmem \
  "https://github.com/PAIR-Systems-Inc/goodmem/releases/latest/download/goodmem-linux-amd64" && \
  chmod +x /usr/local/bin/goodmem && \
  file /usr/local/bin/goodmem && \
  /usr/local/bin/goodmem version || echo "CLI installed but may need server connection"


# Set up non-root dev user
RUN useradd -m -s /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode-nopasswd && \
    chmod 0440 /etc/sudoers.d/vscode-nopasswd && \
    mkdir -p /home/vscode/.goodmem/data/database && \
    chown -R vscode:vscode /home/vscode/.goodmem

USER vscode
WORKDIR /workspace
