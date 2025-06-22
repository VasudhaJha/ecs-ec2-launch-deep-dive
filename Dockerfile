# ----------------------------
# Stage 1 — Build layer
# ----------------------------
FROM python:3.13-slim AS builder

WORKDIR /app

# Install dependencies first - leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ----------------------------
# Stage 2 — Runtime layer
# ----------------------------
FROM python:3.13-slim

WORKDIR /app

# Create a non-root user
RUN useradd --create-home --shell /usr/sbin/nologin appuser

# Copy installed packages from the builder
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
# Copy any CLI tools or dependencies from bin
COPY --from=builder /usr/local/bin /usr/local/bin

# Then copy app code
COPY app/ .

# Change ownership so non-root user owns app directory
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Run app using uvicorn server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "9099"]