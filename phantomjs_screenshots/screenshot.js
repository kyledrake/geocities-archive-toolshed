var page = require('webpage').create()
var system = require('system')
var args = system.args

//viewportSize being the actual size of the headless browser
page.viewportSize = { width: 800, height: 600 }

//the clipRect is the portion of the page you are taking a screenshot of
page.clipRect = { top: 0, left: 0, width: 800, height: 600 }


page.settings.resourceTimeout = 10000; // 10 seconds
page.onResourceTimeout = function(e) {
  page.render(args[2])
  phantom.exit(1)
};

page.open(args[1], function(status) {
  page.render(args[2]) //+'.jpg', {format: 'jpeg', quality: '90'}));
  phantom.exit()
});
