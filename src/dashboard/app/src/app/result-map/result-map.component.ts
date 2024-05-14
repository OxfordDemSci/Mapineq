import {AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges} from '@angular/core';
import * as L from "leaflet";
import {FeatureService} from "../services/feature.service";
import {RegionsLayer} from "../layers/regions-layer";
import {DisplayObject} from "../lib/display-object";

@Component({
  selector: 'app-result-map',
  templateUrl: './result-map.component.html',
  styleUrl: './result-map.component.css'
})
export class ResultMapComponent implements OnInit, AfterViewInit, OnChanges {

  @Input() inputDisplayObject!: DisplayObject;



  private map;
  layerMapOSM: any;
  regionsLayer: any;
  xydata: any;

  constructor(private featureService: FeatureService) {

  } // END CONSTRUCTOR

  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {
      // console.log('!!!!! !!!!! !!!!! !!!!! change in', propName, changes[propName].currentValue);
      const change = changes[propName];
      const valueCurrent  = change.currentValue;
      // const valuePrevious = change.previousValue;
      if (propName === 'inputDisplayObject' && valueCurrent) {
        console.log('ngOnChanges(), "inputDisplayObject":', valueCurrent);
      }
    }
  } // END FUNCTION ngOnChanges

  ngOnInit(): void {
    // console.log('ngOnInit() ... ');

  } // END FUNCTION ngOnInit

  ngAfterViewInit() {
    // console.log('ngAfterViewInit() ...');

    this.initResultMap();
    this.featureService.getTestXYData().subscribe((data) => {
      console.log('data=', data);
      this.xydata = data;
      this.plotData();
    })

  } // END FUNCTION ngAfterViewInit

  initResultMap() {
    this.map = L.map('resultMap');

    this.layerMapOSM = L.tileLayer(
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors',
          minZoom: 0,
          maxZoom: 19 // 21
        });
    this.map.addLayer(this.layerMapOSM);

    this.regionsLayer = RegionsLayer.getLayer(2, 2016);
    this.map.addLayer(this.regionsLayer);

    this.map.fitBounds(L.latLng(53.238, 6.536).toBounds(3000000));
  } // END FUNCTION initResultMap

  resizeMap(): void {
    // console.log('TEST: ', document.getElementById('map').offsetWidth);

    this.map.invalidateSize(true);
    // this.layerMap.redraw();

  } // END FUNCTION resizeMap

  plotData() {
    console.log('plot', this.xydata)
    let result = this.xydata.reduce((map: { [x: string]: any; }, obj: { id: string | number; }) => {
      map[obj.id] = obj;
      return map;
    }, {})
    console.log('AT11', result['AT11']);
    this.changeStyle(result);
    this.addMouseOver(result);
  }

  changeStyle(mapdata:any) {
    let unknown = [];
    let xdata = this.xydata.map((item: any) => Number(item.entity1));
    let ydata = this.xydata.map((item: any) => item.entity2);
    //console.log(xdata);
    let xmax = Math.max(...xdata);
    let ymax = Math.max(...ydata);
    let ymin = Math.min(...ydata);
    console.log('ymin=', ymin)
    this.regionsLayer.options.vectorTileLayerStyles.default = ((properties: any) => {
      if (properties['nuts_id'] === 'HR03')
      console.log('properties', properties['nuts_id'], properties['nuts_name']);
      let entity1 = 0;
      let entity2 = 0;
      if (mapdata[properties['nuts_id']] != undefined)  {
        entity1 = +mapdata[properties['nuts_id']].entity1;
        entity2 = +mapdata[properties['nuts_id']].entity2;
      } else {
        unknown.push(properties['nuts_id']);
      }

      let fillColor = this.getColor(entity1, xmax, entity2, ymax);
      //console.log('fillColor', fillColor);
      //console.log('properties', properties);
      return {
        fill: true, fillColor: fillColor, fillOpacity: 1,
        color: 'rgba(0,0,0,0.78)', opacity: 1, weight: 0.5,
      };
    })
    this.regionsLayer.redraw();
    console.log('nuts_ids not found', unknown);
  }



  getColor(xvalue: number, xmax: number, yvalue: number, ymax: number): any {

    //console.log(xvalue, xmax, yvalue, ymax);
    let ymin = 73;
    let colors = {
      '31' : '#64acbe', '32' : '#627f8c', '33' : '#574249',
      '21' : '#b0d5df', '22' : '#ad9ea5', '23' : '#985356',
      '11' : '#e8e8e8', '12' : '#e4ACAC', '13' : '#c85a5a',
    }
    let index1 = Math.ceil(xvalue/(xmax/3));
    let index2 = Math.ceil((yvalue-ymin)/((ymax-ymin)/3))
    if (xvalue === 17.2) {
      console.log(index1+' '+index2);
    }

    if (index1 === 0 && index2 === 0) {
      return '#FFFFFF';
    }
    return colors[index2.toString() + index1.toString()];
  }


  addMouseOver(popupdata:any): any {
    this.regionsLayer.on('mouseover', ( (event: { layer: { properties: any; }; latlng: L.LatLngExpression; }) => {
      //console.log('click', event);
      const properties = event.layer.properties;
      //console.log('properties', properties)
      if (properties) {
        let content = `<h3>${properties.nuts_name || 'Unknown'}</h3>`;  // Assume that your data might contain a "name" field
        content += '<div>' + JSON.stringify(properties) + '</div>';
        let entity1 = 'no data';
        if (popupdata[properties['nuts_id']] != undefined)  {
          entity1 = popupdata[properties['nuts_id']].entity1;
        }
        let entity2 = 'no data';
        if (popupdata[properties['nuts_id']] != undefined)  {
          entity2 =popupdata[properties['nuts_id']].entity2;
        }
        content += '<div>' + entity1 + '</div>';
        content += '<div>' + entity2 + '</div>';
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

  addLegend(): any {
    for (let x=1;x<=3; x++) {
      for (let y=1;y<=3; y++) {

      }

    }


  }


}
