FROM python:3.11-slim

# System deps for OpenCV headless
RUN apt-get update && \
    apt-get install -y --no-install-recommends libgl1 libglib2.0-0 wget python3-venv && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
RUN pip install --no-cache-dir \
    Pillow \
    ultralytics \
    opencv-python-headless \
    numpy \
    inotify

COPY builder.py .
RUN python3 builder.py --no-venv

# COPY alice.py .

EXPOSE 8080

ENTRYPOINT ["python3", "alice.py", "--port", "8080"]
