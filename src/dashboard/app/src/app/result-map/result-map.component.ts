import {AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges} from '@angular/core';
import * as L from "leaflet";
import {FeatureService} from "../services/feature.service";
import {RegionsLayer} from "../layers/regions-layer";
import {DisplayObject} from "../lib/display-object";
import {
  LeafletControlLegend,
  LeafletControlMapButtonsLeft,
  LeafletControlWatermark
} from "../lib/leaflet-control-custom";

const colors = {
  '31' : '#64acbe', '32' : '#627f8c', '33' : '#574249',
  '21' : '#b0d5df', '22' : '#ad9ea5', '23' : '#985356',
  '11' : '#e8e8e8', '12' : '#e4acac', '13' : '#c85a5a',
}

@Component({
  selector: 'app-result-map',
  templateUrl: './result-map.component.html',
  styleUrl: './result-map.component.css'
})
export class ResultMapComponent implements OnInit, AfterViewInit, OnChanges {

  @Input() inputDisplayObject!: DisplayObject;
  @Input() inputDisplayDataUpdated!: boolean;


  mapLegendDiv: any;

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
      if (propName === 'inputDisplayDataUpdated') { //  && valueCurrent
        console.log('ngOnChanges(), "inputDisplayDataUpdated":', valueCurrent);
        console.log(this.inputDisplayObject.tableFields[0].tableYear + ' ' + this.inputDisplayObject.tableFields[0].tableRegionLevel);
        this.xydata = this.inputDisplayObject.displayData;
        this.regionsLayer = RegionsLayer.getLayer(this.inputDisplayObject.tableFields[0].tableRegionLevel, this.inputDisplayObject.tableFields[0].tableYear);
        this.map.addLayer(this.regionsLayer);
        this.plotData();
        this.addLegend({'xlabel' : this.inputDisplayObject.tableFields[0].tableDescr, 'ylabel' : this.inputDisplayObject.tableFields[1].tableDescr});
      }
    }
  } // END FUNCTION ngOnChanges

  ngOnInit(): void {
    // console.log('ngOnInit() ... ');

  } // END FUNCTION ngOnInit

  ngAfterViewInit() {
    // console.log('ngAfterViewInit() ...');

    this.initResultMap();
    /*
    this.featureService.getRealXYData().subscribe((data) => {
      //console.log('data=', data);
      this.xydata = data;
      this.plotData();
    });
    */

  } // END FUNCTION ngAfterViewInit

  initResultMap() {
    this.map = L.map('resultMap');

    // this.layerMapOSM = L.tileLayer(
    //     'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    //     {
    //       attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors',
    //       minZoom: 0,
    //       maxZoom: 19 // 21
    //     });
    // this.map.addLayer(this.layerMapOSM);

    let Esri_WorldGrayCanvas = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}', {
      attribution: 'Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ',
      maxZoom: 16
    });
    this.map.addLayer(Esri_WorldGrayCanvas);
    // let CartoDB_PositronNoLabels = L.tileLayer('https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png', {
    //   attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
    //   subdomains: 'abcd',
    //   maxZoom: 20
    // });
    // this.map.addLayer(CartoDB_PositronNoLabels);

    new LeafletControlLegend({position: 'bottomright'}).addTo(this.map);
    this.mapLegendDiv = document.getElementById('map_legend_div');
    this.mapLegendDiv.innerHTML = '<h4>Legend</h4>';
    this.mapLegendDiv.innerHTML += '<img id ="scream" alt="legenda"  style="display:none" src="assets/img/legend.png"></img>';
    this.mapLegendDiv.innerHTML += '<canvas id="myCanvas" width="200" height="200" ></canvas>';




    new LeafletControlWatermark().addTo(this.map);

    let mapButtonsDivLeft = new LeafletControlMapButtonsLeft().addTo(this.map);
    // mapButtonsDivLeft.addButton(this.testToggle.bind(this), {id: 'mbl_0', mat_icon: 'near_me_disabled', title: 'start/stop navigatie', toggle: ['near_me', 'near_me_disabled']});
    mapButtonsDivLeft.addButton(this.zoomMapToFit.bind(this), {
      id: 'button_zoom_fit',
      class: 'map_button_zoom_fit',
      title: 'Show complete selection'
    });
    mapButtonsDivLeft.addButton(this.consoleLogData.bind(this), {
      id: 'button_zoom_fit',
      mat_icon: 'terminal',
      title: 'Log data in console ...'
    });

    this.map.fitBounds(L.latLng(53.238, 6.536).toBounds(3000000));
  } // END FUNCTION initResultMap

  resizeMap(): void {
    // console.log('TEST: ', document.getElementById('map').offsetWidth);

    this.map.invalidateSize(true);
    // this.layerMap.redraw();

  } // END FUNCTION resizeMap


  public zoomMapToFit(): void {
    // this.map.fitBounds(this.regionsLayer.getBounds());
    this.map.fitBounds(L.latLng(53.238, 6.536).toBounds(3000000));
  } // END FUNCTION zoomMapToFit


  public consoleLogData() {
    console.log('Current inputDisplayObject.displayData:', this.inputDisplayObject.displayData)
  } // END FUNCTION consoleLogData



  plotData() {
    //console.log('plot', this.xydata)
    let result = this.xydata.reduce((map: { [x: string]: any; }, obj: { geo: string | number; }) => {
      map[obj.geo] = obj;
      return map;
    }, {})
    console.log('AT11', result['AT11']);
    this.changeStyle(result);
    this.addMouseOver(result);
  }

  changeStyle(mapdata:any) {
    let unknown = [];
    let xdata = this.xydata.map((item: any) => Number(item.x));
    let ydata = this.xydata.map((item: any) => item.y);
    //console.log(xdata);
    let xmax = Math.max(...xdata);
    let ymax = Math.max(...ydata);
    let ymin = Math.min(...ydata);
    let xmin = Math.min(...xdata);
    console.log('ymin=', ymin)
    this.regionsLayer.options.vectorTileLayerStyles.default = ((properties: any) => {
      if (properties['nuts_id'] === 'HR03')
      console.log('properties', properties['nuts_id'], properties['nuts_name']);
      let entity1 = 0;
      let entity2 = 0;
      if (mapdata[properties['nuts_id']] != undefined)  {
        entity1 = +mapdata[properties['nuts_id']].x;
        entity2 = +mapdata[properties['nuts_id']].y;
      } else {
        unknown.push(properties['nuts_id']);
      }

      let fillColor = this.getColor(entity1, xmin, xmax, entity2, ymin, ymax);
      //console.log('fillColor', fillColor);
      //console.log('properties', properties);
      return {
        fill: true, fillColor: fillColor, fillOpacity: 1,
        color: 'rgba(255,255,255,0.77)', opacity: 1, weight: 0.5,
      };
    })
    this.regionsLayer.redraw();
    console.log('nuts_ids not found', unknown);
  }



  getColor(xvalue: number, xmin:number, xmax: number, yvalue: number, ymin : number, ymax: number): any {

    //console.log(xvalue, xmin, xmax, yvalue, ymin, ymax);

    let index1 = Math.ceil((xvalue - xmin)/((xmax - xmin)/3));
    let index2 = Math.ceil((yvalue - ymin)/((ymax - ymin)/3))
    if (xvalue === 17.2) {
      console.log(index1+' '+index2);
    }


    if (xvalue === 0 && yvalue === 0) {
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
        if (popupdata[properties['nuts_id']] != 'null')  {
          entity1 = popupdata[properties['nuts_id']].x;
        }
        let entity2 = 'no data';
        if (popupdata[properties['nuts_id']] != 'null')  {
          entity2 =popupdata[properties['nuts_id']].y;
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

  addLegend(info) : any {
    for (let x=1;x<=3; x++) {
      for (let y=1;y<=3; y++) {

      }

    }
    const canvas = document.getElementById("myCanvas") as (HTMLCanvasElement) ;
    const ctx = canvas.getContext("2d");
    ctx.font = "11px Verdana";
    let textparts= info.xlabel.split(" ");
    ctx.fillText(textparts[0] + ' ' + textparts[1], 5, 195);
    const img = document.getElementById("scream") as HTMLImageElement;
    ctx.drawImage(img, 15, 0, 180, 180);
    ctx.save();
    ctx.rotate(-90 * Math.PI / 180);
    ctx.translate(-200,0)
    textparts= info.ylabel.split(" ");
    ctx.fillText(textparts[0] + ' ' + textparts[1], 20, 10);
    ctx.restore();


  }


}
