import {Component, OnInit} from '@angular/core';
import {Router, Event, NavigationStart, NavigationEnd, NavigationError} from "@angular/router";

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnInit {
  title = 'Mapineq interactive map';
  currentRoute: string

  routePageTitles: any;

  constructor(private router: Router) {
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
      }

      if (event instanceof NavigationError) {
        // Hide progress spinner or progress bar
        // Present error to user
        console.log('NavigationError: ', event.error);
      }
    });
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
    console.log('setAppPageTitle():', this.currentRoute, currentRouteClean, this.routePageTitles[currentRouteClean]);
    this.title = this.routePageTitles[currentRouteClean];
  } // END FUNCTION setAppPageTitle


  ngOnInit(): void {
    //console.log('ngOnInit() app.component.ts');
    this.setAppHeight();
    this.setAppPageTitle();
  } // END FUNCTION ngOnInit

  onAppResize(): void {
    // console.log('onAppResize() called ...');
    this.setAppHeight();
  } // END FUNCTION onAppResize

  setAppHeight(): void {
    // console.log('setAppHeight() called ...', window.innerWidth, window.innerHeight);
    document.documentElement.style.setProperty('--app-height', window.innerHeight.toString() + 'px');
  } // END FUNCTION setAppHeight



} // END COMPONENT AppComponent
