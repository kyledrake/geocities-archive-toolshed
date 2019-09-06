const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto(process.argv[2], {
    waitUntil: 'networkidle2',
    timeout: 20000
  });
  await page.screenshot({path: process.argv[3]});
  await browser.close();
})();
