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

