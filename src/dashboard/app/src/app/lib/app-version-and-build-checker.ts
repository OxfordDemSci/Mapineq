// ==============================================================
// needs a file named 'app-version-and-build.json' in 'assets/' directory
//
// content example of this json file:
// {"version": "v0.1.0", "build": 1676649180731, "time": "Fri Feb 17 2023 16:53:00 GMT+0100 (Central European Standard Time)"}
//
// version value is copied from package.json every new build
// build value is updated automatically every new build
// time value is created for human readability
//
// Run the script 'update_app_version_and_build.js' just before building the app:
// replace entry in package.json:
//   "build:prod": "ng build --configuration production --base-href /app/",
// with:
//   "build:prod": "node update_app_version_and_build.js  &&  ng build --configuration production --base-href /app/",
//
// ==============================================================


export class AppVersionAndBuildChecker {

  private appVersionAndBuildUrl: string;

  public appVersionAndBuildCurrent: string;
  public appVersionAndBuildLatest: string;

  public showUpdateDiv: boolean;

  constructor() {
    this.showUpdateDiv = false;

    this.appVersionAndBuildUrl = 'assets/app-version-and-build.json';

    this.appVersionAndBuildCurrent = '...';
    this.appVersionAndBuildLatest = '...';

    this.checkAppVersionsAndBuilds().then(() => { console.log('app version/build checked'); });

  } // END CONSTRUCTOR


  async checkAppVersionsAndBuilds(): Promise<void> {
    const versionAndBuildCurrentJson = await this.getAppVersionAndBuild();
    // console.log('versionAndBuildCurrentJson: ', versionAndBuildCurrentJson);
    this.appVersionAndBuildCurrent = this.makeAppVersionAndBuildString(versionAndBuildCurrentJson);

    const versionAndBuildLatestJson = await this.getAppVersionAndBuild(true);
    // console.log('versionAndBuildLatestJson: ', versionAndBuildLatestJson);
    this.appVersionAndBuildLatest = this.makeAppVersionAndBuildString(versionAndBuildLatestJson);

    // console.log('checkAppVersionsAndBuilds(): ', this.appVersionAndBuildCurrent, this.appVersionAndBuildLatest);

    if (this.appVersionAndBuildLatest !== this.appVersionAndBuildCurrent  &&
      this.appVersionAndBuildLatest !== '??'  &&
      this.appVersionAndBuildCurrent !== '??') {
      this.showUpdateDiv = true;
    } else {
      this.showUpdateDiv = false;
    }
  } // END FUNCTION checkAppVersionsAndBuilds


  private async getAppVersionAndBuild(useCurrentTimeString = false): Promise<any> {
    return fetch(this.appVersionAndBuildUrl + (useCurrentTimeString ? '?t=' + Date.now().toString() : ''))
      .then( (response) => {
        return response.json();
      })
      .then( (responseJson) => {
        // console.log(JSON.stringify(responseJson));
        return responseJson;
      })
      .catch( (error) => {
        console.log('getAppVersionAndBuild() error: ', error);
        return {version: '??', build: -1};
      });
  } // END FUNCTION getAppVersionAndBuild


  makeAppVersionAndBuildString(data): string {
    if (data.build === -1) {
      return '??';
    }
    const appBuildDate = new Date(data.build);
    const appVersion = data.version;
    const locale = 'nl-NL';
    const appBuildDateStr =
      appBuildDate.toLocaleDateString(locale, {year: 'numeric'}) + '-' +
      appBuildDate.toLocaleDateString(locale, {month: '2-digit'}) + '-' +
      appBuildDate.toLocaleDateString(locale, {day: '2-digit'}) + ' ' +
      appBuildDate.toLocaleTimeString(locale, {hour: '2-digit', hour12: false, minute: '2-digit'});
    return '' + appVersion + ' build ' + appBuildDateStr;
  } // END FUNCTION makeAppVersionAndBuildString

  updateAppVersionAndBuild(): void {
    window.open('./?t=' + Date.now().toString(), '_self');
  } // END FUNCTION updateAppVersionAndBuild

} // END CLASS AppVersionChecker
