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


