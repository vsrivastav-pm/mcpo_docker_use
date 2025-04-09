FROM python:3.11-slim
LABEL org.opencontainers.image.title="mcpo"
LABEL org.opencontainers.image.description="Docker image for mcpo (Model Context Protocol OpenAPI Proxy)"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    nodejs \
    npm \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
	
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh

RUN uv pip install --system mcpo mcp-server-fetch

# https://github.com/modelcontextprotocol/servers/tree/main
RUN npm install -g @modelcontextprotocol/server-puppeteer
	
RUN mkdir -p /app/config /app/logs
WORKDIR /app
EXPOSE 8000

ENV MCPO_API_KEY=""

ENV MCPO_LOG_DIR="/app/logs"

RUN uvx --help

RUN echo '#!/bin/bash\n\
date_str=$(date +"%Y%m%d_%H%M%S")\n\
log_file="/app/logs/mcpo_${date_str}.log"\n\
if [ ! -z "$MCPO_API_KEY" ]; then\n\
  uvx mcpo --host 0.0.0.0 --port 8000 --config /app/config/config.json --api-key $MCPO_API_KEY 2>&1 | tee -a "$log_file"\n\
else\n\
  uvx mcpo --host 0.0.0.0 --port 8000 --config /app/config/config.json 2>&1 | tee -a "$log_file"\n\
fi' > /app/start.sh && chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]
