# 建议：如果 ghcr.io 拉取慢，请先在宿主机配置 Docker 镜像加速，或使用代理拉取
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

WORKDIR /app

EXPOSE 7860

ENV PYTHONUNBUFFERED=1

# 【关键修改 1】配置 uv 使用清华源 (TUNA)，加速 Python 库下载
# 这样后续所有的 uv pip install 都会自动走国内镜像
ENV UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV UV_DEFAULT_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple

# 【关键修改 2】替换 Debian 系统源为阿里云镜像
# Bookworm 版本通常使用 debian.sources 文件，这里做兼容处理
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's|security.debian.org/debian-security|mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || sed -i 's|security.debian.org/debian-security|mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list

# # 【关键修改 3】如果需要下载字体，请在 URL 前加 GitHub 代理 (如 ghproxy.net)
# ADD "https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Regular.ttf" /app/
# ADD "https://github.com/timelic/source-han-serif/releases/download/main/SourceHanSerifCN-Regular.ttf" /app/
# ADD "https://github.com/timelic/source-han-serif/releases/download/main/SourceHanSerifTW-Regular.ttf" /app/
# ADD "https://github.com/timelic/source-han-serif/releases/download/main/SourceHanSerifJP-Regular.ttf" /app/
# ADD "https://github.com/timelic/source-han-serif/releases/download/main/SourceHanSerifKR-Regular.ttf" /app/
COPY *.ttf /app/

RUN apt-get update && \
    apt-get install --no-install-recommends -y libgl1 libglib2.0-0 libxext6 libsm6 libxrender1 build-essential && \
    rm -rf /var/lib/apt/lists/*

COPY pyproject.toml .

# 此时 uv 会自动使用上面定义的清华源，速度极快
RUN uv pip install --system --no-cache -r pyproject.toml && babeldoc --version && babeldoc --warmup

COPY . .

ARG CACHEBUST=1

RUN uv pip install --system --no-cache . && \
    uv pip install --system --no-cache --compile-bytecode -U babeldoc "pymupdf<1.25.3" && \
    babeldoc --version && babeldoc --warmup

RUN pdf2zh --version
CMD ["pdf2zh", "--gui"]