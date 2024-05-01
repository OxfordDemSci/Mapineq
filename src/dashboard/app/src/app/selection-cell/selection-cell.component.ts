import {AfterViewInit, Component, EventEmitter, Input, OnChanges, OnInit, Output, SimpleChanges} from '@angular/core';

// import * as L from 'leaflet';


@Component({
  selector: 'app-selection-cell',
  templateUrl: './selection-cell.component.html',
  styleUrl: './selection-cell.component.css'
})
export class SelectionCellComponent implements OnInit, AfterViewInit, OnChanges {

  @Input() inputTableId!: any;
  @Input() inputTableSelection!: any;

  @Output() updateTableSelectionFromCell = new EventEmitter();


  tableId: number;
  tableSelection: any;

  // private map;
  layerMapOSM: any;

  constructor() {} // END CONSTRUCTOR

  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {
      // console.log('!!!!! !!!!! !!!!! !!!!! change in', propName, changes[propName].currentValue);
      const change = changes[propName];
      const valueCurrent  = change.currentValue;
      // const valuePrevious = change.previousValue;
      if (propName === 'inputLocationFrom' && valueCurrent) {
        // console.log('setFrom() activated by ngOnChanges', valueCurrent);
      }
    }
  } // END FUNCTION ngOnChanges

  ngOnInit(): void {
    console.log('ngOnInit() ...');
    this.tableId = this.inputTableId;
    this.tableSelection = this.inputTableSelection;
  } // END FUNCTION ngOnInit

  ngAfterViewInit() {
    console.log('ngAfterViewInit() ...', this.tableId, this.tableSelection);

    setTimeout( () => {
      console.log('timeOut', this.tableId);
      //this.initMap();
    }, 500);
  } // END FUNCTION ngAfterViewInit

  initMap() {
    let mapId = 'map_' + this.tableId.toString();

    console.log('initMap CALLED ... ', mapId);


    let test = document.getElementById(mapId);
    console.log('map element:', test);

    /* /
    this.layerMapOSM = L.tileLayer(
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors>',
          minZoom: 0,
          maxZoom: 21
        });

    this.map = L.map(mapId);

    this.map.addLayer(this.layerMapOSM);

    this.map.fitBounds(L.latLng(52.038, 5.314).toBounds(300000));
    /* */




  } // END FUNCTION initMap



} // END CLASS SelectionCellComponent
