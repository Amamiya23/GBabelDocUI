FROM h9ie6ws364v1xs.xuanyuan.run/astral/uv:python3.13-bookworm-slim

WORKDIR /app

EXPOSE 7860

ENV PYTHONUNBUFFERED=1

ENV UV_INDEX_URL=https://mirrors.aliyun.com/pypi/simple
ENV UV_DEFAULT_INDEX=https://mirrors.aliyun.com/pypi/simple

RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's|security.debian.org/debian-security|mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || sed -i 's|security.debian.org/debian-security|mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list


# ADD "https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Regular.ttf" /app/
# ADD "https://github.com/timelic/source-han-serif/releases/download/main/SourceHanSerifCN-Regular.ttf" /app/
# ADD "https://github.com/timelic/source-han-serif/releases/download/main/SourceHanSerifTW-Regular.ttf" /app/
# ADD "https://github.com/timelic/source-han-serif/releases/download/main/SourceHanSerifJP-Regular.ttf" /app/
# ADD "https://github.com/timelic/source-han-serif/releases/download/main/SourceHanSerifKR-Regular.ttf" /app/
COPY fonts/*.ttf /app/

RUN apt-get update && \
    apt-get install --no-install-recommends -y libgl1 libglib2.0-0 libxext6 libsm6 libxrender1 build-essential && \
    rm -rf /var/lib/apt/lists/*

COPY pyproject.toml .


RUN uv pip install --system --no-cache -r pyproject.toml && babeldoc --version && babeldoc --warmup

COPY . .

ARG CACHEBUST=1

RUN uv pip install --system --no-cache . && \
    uv pip install --system --no-cache --compile-bytecode -U babeldoc "pymupdf<1.25.3" && \
    babeldoc --version && babeldoc --warmup

RUN pdf2zh --version
CMD ["pdf2zh", "--gui"]