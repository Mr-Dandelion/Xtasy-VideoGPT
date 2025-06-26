FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

ARG USERNAME=lanfeng
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONIOENCODING=utf-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH="/home/${USERNAME}/.local/bin:${PATH}"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    python3-pip python3-dev python3-venv python-is-python3 \
    build-essential git curl ca-certificates \
    cmake ninja-build ffmpeg libglib2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd  --uid ${USER_UID} --gid ${USER_GID} --create-home ${USERNAME}

WORKDIR /home/${USERNAME}
COPY requirements.txt .

ARG PYPI_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple
RUN echo "[global]\nindex-url = ${PYPI_MIRROR}" > /etc/pip.conf

RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt \
                   imageio imageio-ffmpeg decord==0.6.0 && \
    pip install --no-cache-dir \
      flash-attn==2.5.6 \
      --extra-index-url https://flash-attention-cuda-releases.s3.us-west-2.amazonaws.com/cu121/ # 官方 CDN

COPY --chown=${USERNAME}:${USERNAME} --chmod=755 . .

USER ${USERNAME}

ENTRYPOINT ["bash", "eval/vcgbench/inference/run_ddp_inference.sh"]