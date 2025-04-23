# Stage 1: Scraping with Puppeteer
FROM node:20 AS scraper
WORKDIR /app
COPY scraper/package.json ./
RUN npm install
COPY scraper/index.js ./

# Install Chromium
RUN apt-get update && apt-get install -y chromium && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Scrape the specified URL
ARG SCRAPE_URL=https://example.com
RUN mkdir /data && node index.js $SCRAPE_URL

# Stage 2: Serving with Flask
FROM python:3.11-slim
WORKDIR /app
COPY server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server/app.py ./
COPY --from=scraper /data/scraped.html /data/scraped.html

EXPOSE 5000
CMD ["python", "app.py"]

