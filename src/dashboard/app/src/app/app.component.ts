import {AfterViewInit, Component} from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements AfterViewInit {
  title = 'Mapineq dashboard';


  ngAfterViewInit(): void {
    this.setAppSizes();
  } // END FUNCTION ngAfterViewInit

  setAppSizes(): void {
    // console.log('setAppSizes() called ...', window.innerWidth, window.innerHeight);
    document.documentElement.style.setProperty('--app-height', window.innerHeight.toString() + 'px');
    document.documentElement.style.setProperty('--app-width', window.innerWidth.toString() + 'px');
  } // END FUNCTION setAppSizes

  onAppResize(): void {
    // console.log('onAppResize() called ...');
    this.setAppSizes();
  } // END FUNCTION onAppResize




}
