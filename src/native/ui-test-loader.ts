declare var __dirname:string;

var fs = require('fs');
var app = require('app');  // Module to control application life.
var BrowserWindow = require('browser-window');  // Module to create native browser window.

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is GCed.
var mainWindow = null;

// Quit when all windows are closed.
app.on('window-all-closed', () => app.quit());

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
app.on('ready', () => {
  // Create the browser window.
  mainWindow = new BrowserWindow({width: 800, height: 600});

  // and load the index.html of the app.
  var [_, _, testName] = process.argv;
  if (testName === "index") {
      mainWindow.loadUrl(`file://${__dirname}/index.html`);
  } else {
      var fs = require('fs');
      fs.readFile(__dirname + "/ui-test.template.html", 'utf8', (err,data) => {
          var result = data.replace("$$ENTER_HERE$$", testName);
          fs.writeFile(`${__dirname}/ui-test-${testName}.html`, result, 'utf8', (err) => {
              mainWindow.loadUrl(`file://${__dirname}/ui-test-${testName}.html`);
          });
      });
  }

  // Open the devtools.
  // mainWindow.openDevTools();

  // Emitted when the window is closed.
  mainWindow.on('closed', () => {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should delete the corresponding element.
    mainWindow = null;
  });
});
