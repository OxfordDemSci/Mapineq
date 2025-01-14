import {AfterViewInit, Component, OnInit} from '@angular/core';
import {Router, Event, NavigationStart, NavigationEnd, NavigationError} from "@angular/router";
import {AppVersionAndBuildChecker} from "./lib/app-version-and-build-checker";
import {DialogAppVersionAndBuildInfo} from "./lib/dialog-app-version-and-build-info.component";
import {MatDialog} from "@angular/material/dialog";

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements AfterViewInit {
  title = 'Mapineq interactive map';
  currentRoute: string

  routePageTitles: any;

  versionChecker: AppVersionAndBuildChecker;

  constructor(public dialog: MatDialog, private router: Router) {
    this.currentRoute = '/';

    this.routePageTitles = {
      '': 'Mapineq interactive map', // mss niet nodig, alleen na update /?t=... komt dan natuurlijk niet voor
      '/': 'Mapineq interactive map',
      '/datacatalogue': 'Mapineq data catalogue',
      '/case': 'Mapineq interactive map - Case study'
    };


    this.router.events.subscribe((event: Event) => {
      if (event instanceof NavigationStart) {
        // Show progress spinner or progress bar
        //console.log('Route change detected ...');
      }

      if (event instanceof NavigationEnd) {
        // Hide progress spinner or progress bar
        // this.currentRoute = event.url;
        // console.log(event);
        // console.log('***** new route:', event.urlAfterRedirects);
        this.currentRoute = event.urlAfterRedirects;
        this.setAppPageTitle();
        this.checkAppVersionAndBuild();
      }

      if (event instanceof NavigationError) {
        // Hide progress spinner or progress bar
        // Present error to user
        console.log('NavigationError: ', event.error);
      }
    });
    this.versionChecker = new AppVersionAndBuildChecker();
  } // END FUNCTION constructor


  setAppPageTitle(): void {
    let currentRouteClean = this.currentRoute;
    if (currentRouteClean.indexOf('?') > -1) {
      currentRouteClean = currentRouteClean.substring(0, currentRouteClean.indexOf('?'));
    }
    if (currentRouteClean.indexOf(';') > -1) {
      currentRouteClean = currentRouteClean.substring(0, currentRouteClean.indexOf(';'));
    }
    if (currentRouteClean.substring(1).indexOf('/') > -1) {
      currentRouteClean = currentRouteClean.substring(0, currentRouteClean.substring(1).indexOf('/') + 1);
    }
    // console.log('setAppPageTitle():', this.currentRoute, currentRouteClean, this.routePageTitles[currentRouteClean]);
    this.title = this.routePageTitles[currentRouteClean];
  } // END FUNCTION setAppPageTitle

  checkAppVersionAndBuild() {
    console.log('checkAppVersionAndBuild() ...');

    this.versionChecker.checkAppVersionsAndBuilds()
        .then( () => {
          if (this.versionChecker.showUpdateDiv) {
            this.showAppVersionAndBuildInfoDialog();
          }
        });
  } // END FUNCTION checkAppVersionAndBuild


  showAppVersionAndBuildInfoDialog(): void {

    this.versionChecker.checkAppVersionsAndBuilds()
        .then( () => {

          let dialogData = {
            title: 'App version and build',
            content: 'some text with<br>html<ul><li>aaa</li><li>bbb</li></ul>',
            data: this.versionChecker
          }

          const appVersionAndBuildInfoDialogRef = this.dialog.open(DialogAppVersionAndBuildInfo, {data: dialogData});

          appVersionAndBuildInfoDialogRef.afterClosed().subscribe(result => {
            console.log('appVersionAndBuildInfoDialogRef.afterClosed(), result: ', result);

            if (typeof result === 'undefined') {
              console.log(' APP VERSION AND BUILD INFO DIALOG closed without result(?)');
            } else {
              console.log(' APP VERSION AND BUILD INFO DIALOG result: ', result);

              if (result.data.showUpdateDiv) {
                this.versionChecker.updateAppVersionAndBuild();
              }

            }
          });
        });

  } // END FUNCTION showAppVersionAndBuildInfoDialog


  // ngOnInit(): void {
  // } // END FUNCTION ngOnInit

  ngAfterViewInit(): void {
    //console.log('ngOnInit() app.component.ts');
    this.setAppHeight();
    this.setAppPageTitle();
    this.checkAppVersionAndBuild();
  } // END FUNCTION ngAfterViewInit

  onAppResize(): void {
    // console.log('onAppResize() called ...');
    this.setAppHeight();
  } // END FUNCTION onAppResize

  setAppHeight(): void {
    // console.log('setAppHeight() called ...', window.innerWidth, window.innerHeight);
    document.documentElement.style.setProperty('--app-height', window.innerHeight.toString() + 'px');
  } // END FUNCTION setAppHeight



} // END COMPONENT AppComponent
