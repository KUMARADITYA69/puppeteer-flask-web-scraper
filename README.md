# Puppeteer + Flask Web Scraper on Kubernetes

## 🚀 Overview

This project demonstrates how to use **Node.js with Puppeteer** to scrape content from a website and **Flask (Python)** to serve the content over HTTP. The app is containerized with Docker and deployed on **Kubernetes (Minikube)**, exposed using an **NGINX Ingress Controller** with path-based routing.

---

## 🛠️ Technologies Used

- **Node.js + Puppeteer** – For scraping HTML content from a URL
- **Python + Flask (2.3.3)** – For serving the scraped content
- **Docker** – To build and containerize the app
- **Kubernetes + Minikube** – For local cluster deployment
- **NGINX Ingress Controller** – For external access with clean URLs

---

## 📁 Folder Structure

```
puppeteer-flask-app/
├── Dockerfile
├── scraper/
│   ├── index.js
│   └── package.json
└── server/
    ├── app.py
    └── requirements.txt
```

---

## 🧰 Local Setup

### ✅ Install Docker

```bash
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
```

### Optional (run Docker as non-root):

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 📦 Create Project Structure

```bash
mkdir puppeteer-flask-app
cd puppeteer-flask-app
mkdir scraper server
touch Dockerfile
```

## 📜 Code Files

### scraper/package.json  

```json
{
  "name": "scraper",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "puppeteer": "^21.3.8"
  }
}
```

### scraper/index.js

```javascript
const puppeteer = require('puppeteer');
const fs = require('fs');
const url = process.argv[2];

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: 'networkidle2' });
  const html = await page.content();
  fs.writeFileSync('/data/scraped.html', html);
  await browser.close();
})();
```

### server/requirements.txt 

```
flask==2.3.3
```

### server/app.py

```python
from flask import Flask, send_file
import os

app = Flask(__name__)

@app.route('/')
def home():
    if os.path.exists('/data/scraped.html'):
        return send_file('/data/scraped.html')
    return "No content scraped yet. Please rebuild the image with a SCRAPE_URL.", 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### 🐳 Dockerfile

```Dockerfile
### Stage 1: Scraper
FROM node:20 AS scraper
WORKDIR /app
COPY scraper/package.json ./
RUN npm install
COPY scraper/index.js ./
RUN apt-get update && apt-get install -y chromium && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ARG SCRAPE_URL=https://kubernetes.io
RUN mkdir /data && node index.js $SCRAPE_URL

### Stage 2: Flask Server
FROM python:3.11-slim
WORKDIR /app
COPY server/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY server/app.py ./
COPY --from=scraper /data/scraped.html /data/scraped.html
EXPOSE 5000
CMD ["python", "app.py"]
```

## ☸️ Kubernetes Deployment

### 🧪 Start Minikube and Use Local Docker

```bash
minikube start
eval $(minikube docker-env)
docker build -t puppeteer-flask-app:latest .
```

### 🧬 Deployment (deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: puppeteer-flask-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: puppeteer-flask-app
  template:
    metadata:
      labels:
        app: puppeteer-flask-app
    spec:
      containers:
        - name: puppeteer-flask-app
          image: puppeteer-flask-app:latest
          imagePullPolicy: Never
          ports:
            - containerPort: 5000
```

### 📦 Service (service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: puppeteer-flask-app
spec:
  selector:
    app: puppeteer-flask-app
  type: NodePort
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
      nodePort: 30036
```

### 🔀 Ingress (ingress.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: puppeteer-flask-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: puppeteer.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: puppeteer-flask-app
                port:
                  number: 5000
```

### 🧭 Apply Kubernetes Resources

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

### 🚦 Enable Ingress

```bash
minikube addons enable ingress
```

### 🌍 DNS Mapping

Edit your `/etc/hosts`

```bash
sudo nano /etc/hosts
```

Add this line (replace IP with your Minikube IP):

```
192.168.49.2 puppeteer.local
```

### 🌐 Access Your App

Open the browser and navigate to:

```
http://puppeteer.local/
```

## ✅ Final Thoughts

This project is a strong demonstration of integrating multiple languages and tools into a cohesive and modular workflow. We’ve shown how Node.js with Puppeteer can be used to programmatically scrape dynamic web content, while Python with Flask enables lightweight and effective hosting of that content.

Using Docker multi-stage builds, the final image remains slim and efficient. With Kubernetes orchestrating the deployment and NGINX Ingress managing traffic, we follow modern infrastructure practices that support both development and scalability.

Whether you’re experimenting with cross-language workflows or deploying full-stack microservices locally, this project gives you a foundational template to build upon.
