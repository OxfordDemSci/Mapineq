// ==============================================================
// needs a file named 'app-version-and-build.json' in 'assets/' directory
//
// content example of this json file:
// {"version": "v0.1.0", "build": 1676649180731, "time": "Fri Feb 17 2023 16:53:00 GMT+0100 (Central European Standard Time)"}
//
// version value is copied from package.json in the script below
// build value is updated in the script below
// time value is created for human readability
//
// Run THIS script just before building the app:
// replace entry in package.json:
//   "build:prod": "ng build --configuration production --base-href /app/",
// with:
//   "build:prod": "node update_app_version_and_build.js  &&  ng build --configuration production --base-href /app/",
//
// ==============================================================

let versionAndBuildFilePath = 'src/assets/app-version-and-build.json';
let package = require("./package.json");
let packageVersion = package.version;

const newBuildTime = Date().toLocaleString();
const newBuildTimestamp = Date.now().toString();
console.log(newBuildTime);
console.log('Created new build timestamp:', newBuildTimestamp);
console.log('');

console.log('start update "' + versionAndBuildFilePath + '"');
let lineToWrite = '{"version": "v' + packageVersion + '", "build": ' + newBuildTimestamp + ', "time": "' + newBuildTime + '"}';
let fs = require('fs')
fs.readFile(versionAndBuildFilePath, 'utf8', function (err,data) {
  if (err) {
    return console.log('Error reading version/build: ', err);
  }
  console.log('   old content:', data);

  fs.writeFile(versionAndBuildFilePath, lineToWrite, 'utf8', function (err) {
    if (err) {
      return console.log('Error writing version/build: ', err);
    } else {
      console.log('   new content:', lineToWrite + '' );
      console.log('ended update "' + versionAndBuildFilePath + '" successfully');
      console.log('\n');
    }
  });

});


