# Base image
FROM python:3.10

# Set working directory
WORKDIR /app

# Copy requirements first (để cache layer)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose Streamlit default port
EXPOSE 8080

# Run Streamlit app
CMD ["streamlit", "run", "frontend.py", "--server.port=8080", "--server.address=0.0.0.0"]