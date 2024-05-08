import {AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges} from '@angular/core';
import {DataSource} from "../usercontrols/usercontrols.component";
import L from "leaflet";
import 'leaflet.vectorgrid/dist/Leaflet.VectorGrid.bundled.js';
import 'leaflet/dist/leaflet.css';
import {FeatureService} from "../services/feature.service";
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
  regionsLayer: any;

  @Input() selectedYear = 2015;
  @Input() selectedTable?: DataSource;
  @Input() selectedNuts?: any;

  data: any;

  constructor(private featureService: FeatureService) {
  }


  ngOnChanges(changes: SimpleChanges): void {
    if (this.map === undefined) {
      return;
    }
    for (const propName in changes) {
      const chng = changes[propName];
      const cur = JSON.stringify(chng.currentValue);
      const prev = JSON.stringify(chng.previousValue);
      console.log(`${propName}: currentValue = ${cur}, previousValue = ${prev}`);
      if (propName === 'selectedTable') {
        this.selectTable();
      }
      if (propName === 'selectedYear') {
        this.selectYear();
      }
      if (propName === 'selectedNuts') {
        //console.log('jooooooo nuts');
        this.selectNuts();
      }
    }
  }

  ngOnInit(): void {
    //this.initLayers();
    // this.featureService.getAllSources().subscribe((data) => {
    //   console.log('sources ', data);
    //
    // });
    //"DEMO_R_D2JAN"
    let table = 'BD_SIZE_R3';
    this.featureService.getInfoByReSource(table).subscribe((data) =>{
      console.log('info of ', table, ': ', data);
    });
    // this.featureService.getResourceByYear(2012).subscribe((data) =>{
    //   console.log('resources by Year', data);
    // });
    this.featureService.getSourcesByYearAndNutsLevel('2014', '2').subscribe((data) =>{
      console.log('resources by year, nutslevel ', data);
    });
    this.featureService.getColumnValuesBySource('BD_SIZE_R3', '2014', '2').subscribe((data) =>{
      console.log('ColumnValuesBySource ', data);
    });
  }

  ngAfterViewInit(): void {
    this.initMap();
  }

  initLayers(nutsid: number) {
    let year = 2015;
    //let nutsid = 3;
    let nutsUrl = "https://mapineqtiles.web.rug.nl/" + "areas.get_nuts_areas_tiles" + "/{z}/{x}/{y}.pbf" + "?year=" + year + "&intlevel=" + nutsid

    let options = {
      // @ts-ignore
      rendererFactory: L.canvas.tile,
      interactive: true,
      vectorTileLayerStyles: {
        default: {
          weight: 1,
          color: '#da0a0a',
          fill: true,
          fillColor: '#DA0A0AFF',
          fillOpacity: 0.1,
        }
      }
    }
    // @ts-ignore
    this.regionsLayer = L.vectorGrid.protobuf(nutsUrl, options);
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
    // this.featureService.getNutsAreas(2).subscribe((data) => {
    //   L.geoJSON(data, {style: {
    //       "color": "#ff7800",
    //       "weight": 2,
    //       "opacity": 0.65
    //     }}).addTo(this.map);
    // });
    this.initLayers(2);
    this.map.addLayer(this.regionsLayer);
    //this.regionslayer.setFeatureStyle()
    //this.regionsLayer.options.vectorTileLayerStyles.default.weight = 2;

    //this.regionsLayer.redraw();
    this.addData();
    this.regionsLayer.on('mouseover', ( (event: { layer: { properties: any; }; latlng: L.LatLngExpression; }) => {
      //console.log('click', event);
      const properties = event.layer.properties;
      //console.log('properties', properties)
      if (properties) {
        let content = `<h3>${properties.nuts_name || 'Unknown'}</h3>`;  // Assume that your data might contain a "name" field
        content += '<div>' + JSON.stringify(properties) + '</div>';
        let entity = 'no data';
        if (this.data[properties['nuts_id']] != undefined)  {
          entity = this.data[properties['nuts_id']].entity1;
        }
        content += '<div>' +entity + '</div>';
        // You can place the popup at the event latlng or on the layer.
        L.popup()
          .setContent(content)
          .setLatLng(event.latlng)
          .openOn(this.map);
      } else {
        L.popup().close();
      }

    }));

  }


  addData(): void {

    this.featureService.getFeaturesByYear(this.selectedYear,this.selectedTable.table).subscribe((returnedData:any) => {

      let result = returnedData.reduce((map: { [x: string]: any; }, obj: { id: string | number; }) => {
        map[obj.id] = obj;
        return map;
      }, {})
      console.log('ITG1', result['ITG1']);
      this.changeStyle(result);
      this.data = result;
    });

  }

  changeStyle(data:any) {
    let unknown = [];
    this.regionsLayer.options.vectorTileLayerStyles.default = ((properties: any) => {
      //console.log('properties', properties['nuts_id']);
      let entity = 0;
      if (data[properties['nuts_id']] != undefined)  {
        entity = +data[properties['nuts_id']].entity1;
      } else {
        unknown.push(properties['nuts_id']);
      }

      let fillColor = this.getColor(this.selectedTable.maxvalue, entity);
      //console.log('fillColor', fillColor);
      let style = {
        fill: true, fillColor: fillColor, fillOpacity: 0.9,
        color: 'rgb(230,21,21)', opacity: 1, weight: 0.5,
      };
      //console.log('properties', properties);
      return style;
    })
    this.regionsLayer.redraw();
    console.log('nuts_ids not found', unknown);
  }


  selectTable() {
    // @ts-ignore
    //this.regionslayer.changeTable('pgtileserv.' + this.selectedTable?.table, this.selectedYear.toString(), this.selectedTable.maxvalue);
    //this.regionslayer.changeStyle();
    this.addData();
  }

  selectYear(): void {
    console.log('year', this.selectedYear);
    //this.regionslayer.setYear(this.selectedYear.toString());
  }


  selectNuts(): void {
    //this.regionslayer.setNuts(this.selectedNuts, this.selectedYear);
    //this.regionslayer.set
    this.map.removeLayer(this.regionsLayer);
    this.initLayers(this.selectedNuts);
    this.map.addLayer(this.regionsLayer);


  }

  getColor(max: number | undefined, entity: number): string {

    // @ts-ignore
    const divider = max/7;
    let colors = ['rgb(254,240,217)','rgb(253,212,158)','rgb(253,187,132)',
      'rgb(252,141,89)','rgb(239,101,72)','rgb(215,48,31)','rgb(153,0,0)'];
    let index = Math.ceil(entity/divider);
    //console.log('index=',index);
    return colors[index];
  }


}
