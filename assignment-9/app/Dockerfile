FROM python:3.8-alpine

# Keeps Python from generating .pyc files in the container
# Turns off buffering for easier container logging
# Force UTF8 encoding for funky character handling
# Needed so imports function properly
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1 
ENV PYTHONIOENCODING=utf-8
ENV PYTHONPATH=/app

ENV PROJECT_ID=ds561-amahr
ENV TOPIC_ID=ds561-amahr-hw9-pubsub-topic

# Install project dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Place where the app lives in the container
WORKDIR /app
COPY . /app

# During debugging, this entry point will be overridden. 
CMD ["python", "/app/main.py"]