FROM node:24-bookworm-slim

LABEL org.opencontainers.image.title="opencode-config-template" \
      org.opencontainers.image.description="OpenCode standalone web endpoint - configurable agent/skill runner" \
      org.opencontainers.image.source="https://github.com/darellchua2/opencode-config-template"

ARG OPENCODE_VERSION=1.4.17

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        ca-certificates \
        curl \
        git \
        openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g "opencode-ai@${OPENCODE_VERSION}" \
    typescript \
    ts-node

RUN python3 -m venv /opt/python-env
ENV PATH="/opt/python-env/bin:${PATH}"

RUN pip install --no-cache-dir \
    "openpyxl>=3.1.0" \
    "pandas>=3.0.0" \
    "pdfplumber>=0.11.0" \
    "requests>=2.32.0" \
    "numpy>=2.0.0" \
    "fastapi>=0.115.0"

RUN useradd -m -d /home/opencode -s /bin/bash opencode

COPY . /app/

RUN chmod +x /app/docker-entrypoint.sh \
    && mkdir -p /home/opencode/.local/share/opencode \
    && chown -R opencode:opencode /app /home/opencode

USER opencode

WORKDIR /app

ENV OPENCODE_SERVER_PORT=4096 \
    OPENCODE_SERVER_HOST=0.0.0.0

EXPOSE 4096

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:${OPENCODE_SERVER_PORT}/global/health || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]
