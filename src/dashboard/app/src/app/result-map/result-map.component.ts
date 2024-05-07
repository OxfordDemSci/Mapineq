import {AfterViewInit, Component, OnChanges, OnInit, SimpleChanges} from '@angular/core';
import * as L from "leaflet";

@Component({
  selector: 'app-result-map',
  templateUrl: './result-map.component.html',
  styleUrl: './result-map.component.css'
})
export class ResultMapComponent implements OnInit, AfterViewInit, OnChanges {

  private map;
  layerMapOSM: any;


  constructor() {

  } // END CONSTRUCTOR

  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {
      // console.log('!!!!! !!!!! !!!!! !!!!! change in', propName, changes[propName].currentValue);
      const change = changes[propName];
      const valueCurrent  = change.currentValue;
      // const valuePrevious = change.previousValue;
      if (propName === 'inputTableSelection' && valueCurrent) {
        // console.log('setFrom() activated by ngOnChanges', valueCurrent);
      }
    }
  } // END FUNCTION ngOnChanges

  ngOnInit(): void {
    console.log('ngOnInit() ... ');

  } // END FUNCTION ngOnInit

  ngAfterViewInit() {
    console.log('ngAfterViewInit() ...');

    this.initResultMap();

  } // END FUNCTION ngAfterViewInit

  initResultMap() {
    let mapId = 'resultMap';
    console.log('initResultMap CALLED ... ', mapId);

    this.layerMapOSM = L.tileLayer(
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors',
          minZoom: 0,
          maxZoom: 19 // 21
        });

    this.map = L.map(mapId);

    this.map.addLayer(this.layerMapOSM);

    this.map.fitBounds(L.latLng(53.238, 6.536).toBounds(3000000));



  } // END FUNCTION initResultMap

  resizeMap(): void {
    // console.log('TEST: ', document.getElementById('map').offsetWidth);

    this.map.invalidateSize(true);
    // this.layerMap.redraw();

  } // END FUNCTION resizeMap


}
