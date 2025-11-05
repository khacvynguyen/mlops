FROM python:3.10

WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy all source code
COPY . .

# Expose FastAPI port
EXPOSE 8080

# Start FastAPI using Uvicorn
CMD ["uvicorn", "backend:app", "--host", "0.0.0.0", "--port", "8080"]