import {AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges} from '@angular/core';
import {DataSource} from "../usercontrols/usercontrols.component";
import L from "leaflet";
import 'leaflet.vectorgrid/dist/Leaflet.VectorGrid.bundled.js';
import 'leaflet/dist/leaflet.css';
//import {vectorServer} from "../layers/base-layer";
//import {RegionsLayer} from "../layers/regions-layer";

@Component({
  selector: 'app-map',
  templateUrl: './map.component.html',
  styleUrl: './map.component.css'
})
export class MapComponent implements OnInit, AfterViewInit, OnChanges {

  private map;
  layerMapOSM: any;
  regionslayer: any;

  @Input() selectedYear = 2015;
  @Input() selectedTable?: DataSource;
  @Input() selectedNuts?: any;

  ngOnChanges(changes: SimpleChanges): void {

    for (const propName in changes) {
      const chng = changes[propName];
      const cur  = JSON.stringify(chng.currentValue);
      const prev = JSON.stringify(chng.previousValue);
      console.log(`${propName}: currentValue = ${cur}, previousValue = ${prev}`);
      if (propName === 'selectedTable') {
        this.selectTable();
      }
      if (propName === 'selectedYear') {
        this.selectYear();
      }
      if (propName === 'selectedNuts') {
        console.log('jooooooo nuts');
        this.selectNuts();
      }
    }
  }

  ngOnInit(): void {
    this.initLayers();
  }

  ngAfterViewInit(): void {
    this.initMap();
  }

  initLayers() {
    let year = 2015;
    let nutsid = 2;
    let nutsUrl =  "https://mapineqtiles.web.rug.nl/" + "areas.get_nuts_areas_tiles" + "/{z}/{x}/{y}.pbf" + "?year=" + year + "&intlevel=" + nutsid

    let options = {
      // @ts-ignore
      rendererFactory: L.canvas.tile,
      vectorTileLayerStyles: {
        default: {
          weight: 1,
          color: '#da0a0a',
        }
      }
    }
    // @ts-ignore
    this.regionslayer =  L.vectorGrid.protobuf(nutsUrl, options);
  }

  initMap() {
    this.layerMapOSM = L.tileLayer(
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors',
        minZoom: 0,
        maxZoom: 21
      });

    this.map = L.map('map');

    this.map.addLayer(this.layerMapOSM);

    this.map.fitBounds(L.latLng(53.238, 6.536).toBounds(3000000));
    this.map.addLayer(this.regionslayer);
  }

  selectTable() {
    // @ts-ignore
    //this.regionslayer.changeTable('pgtileserv.' + this.selectedTable?.table, this.selectedYear.toString(), this.selectedTable.maxvalue);
    //this.regionslayer.changeStyle();

  }

  selectYear(): void {
    console.log('year', this.selectedYear);
    //this.regionslayer.setYear(this.selectedYear.toString());
  }


  selectNuts(): void {
    //this.regionslayer.setNuts(this.selectedNuts, this.selectedYear);
    //this.regionslayer.set
  }




}
