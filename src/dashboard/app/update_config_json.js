// ==============================================================
// writes a file named 'config.json' in 'src/assets/' directory
//
// content example of this json file:
// {"apiUrl": "__DOMAIN_NAME__", "apiPath": "__PATH_TO_REST_SERVICES__"}
// e.g.
// {"apiUrl": "http://localhost:8080", "apiPath": "/mapsrugbackend/services/Rest/"}
//
// version value is copied from package.json in the script below
// build value is updated in the script below
// time value is created for human readability
//
// Run THIS script before building the app:
// place entry in package.json:
//   "setup __POSTFIX__": "node update_config_json.js  __POSTFIX__",
//   e.g.
//   "setup TEST": "node update_config_json.js test",
//
// expects file in ../../setup/ with name:
//   "config_"__POSTFIX__
//   e.g.
//   "config_test"
//
// ==============================================================
if (process.argv.length > 2) {

  let fileName = 'src/setup/config_' + process.argv[2] + '.json';
  let configFileName = 'src/assets/config.json';


  console.log('Reading config file data from: ', fileName);

  let fs = require('fs')
  fs.readFile(fileName, 'utf8', function (err,data) {
    if (err) {
      return console.log('Error reading ' + fileName + ': ' , err);
    }
    console.log('content:');
    console.log('----- -----');
    console.log(data);
    console.log('----- -----');
    console.log('Updating ' + configFileName + ' ...');

    fs.writeFile(configFileName, data, 'utf8', function (err) {
      if (err) {
        return console.log('Error writing configfile: ', err);
      } else {
        console.log('Config updated successfully!');
        console.log('\n');
      }
    });


  });


} else {
  console.log('Expecting ONE argument: \'node update_config_json.js _postfix_\'');
}

