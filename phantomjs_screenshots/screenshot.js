const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  await page.setRequestInterception(true);

  page.on('request', req => {
    if (req.isNavigationRequest() && req.frame() === page.mainFrame() && !req.url().match(process.argv[2]+'/?')) {
      // no redirect chain means the navigation is caused by setting `location.href`
      req.respond(req.redirectChain().length
        ? { body: '' } // prevent 301/302 redirect
        : { status: 204 } // prevent navigation by js
      )
    } else {
      req.continue()
    }
  })

  await page.goto(process.argv[2], {
    waitUntil: 'networkidle2',
    timeout: 20000
  });

  await page.screenshot({path: process.argv[3]});
  await page.close();
  await browser.close();
})();
