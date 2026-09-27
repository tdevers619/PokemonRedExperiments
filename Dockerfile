FROM python:3.10-slim

# build-essential: hnswlib builds from source. git: mediapy comes from GitHub.
# xvfb/x11vnc/novnc: virtual display you view in the browser.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential git ffmpeg \
        xvfb x11vnc novnc websockify fluxbox \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements-docker.txt .
# DEVICE=cpu (default) installs CPU-only torch first, keeping the image several GB smaller.
# DEVICE=gpu skips that, so requirements-docker.txt pulls the CUDA 11.7 torch build from PyPI.
# --no-deps: only torch comes from the PyTorch index; its dependencies resolve from PyPI
# in the second install, since requirements-docker.txt pins the same torch version.
ARG DEVICE=cpu
RUN if [ "$DEVICE" = "cpu" ]; then \
        pip install --no-cache-dir --no-deps torch==2.0.1 --index-url https://download.pytorch.org/whl/cpu; \
    fi \
 && pip install --no-cache-dir -r requirements-docker.txt

COPY *.state ./
COPY baselines ./baselines
COPY docker-entrypoint.sh /usr/local/bin/
# Strip CRLF in case the script was saved with Windows line endings
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

ENV DISPLAY=:99
WORKDIR /app/baselines
EXPOSE 6080
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["python", "run_pretrained_interactive.py"]
