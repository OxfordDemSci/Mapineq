import {AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges, ViewChild} from '@angular/core';
import * as L from "leaflet";

import 'leaflet.vectorgrid/dist/Leaflet.VectorGrid.bundled.js';

import {FeatureService} from "../services/feature.service";
import {RegionsLayer} from "../layers/regions-layer";
import {DisplayObject} from "../lib/display-object";
import {
  LeafletControlGraph,
  LeafletControlLegend,
  LeafletControlMapButtonsLeft,
  LeafletControlWatermark
} from "../lib/leaflet-control-custom";
import {GraphComponent} from "../graph/graph.component";


/*
const iconRetinaUrl = 'assets/leaflet/marker-icon-2x.png';
const iconUrl = 'assets/leaflet/marker-icon.png';
const shadowUrl = 'assets/leaflet/marker-shadow.png';
const iconDefault = L.icon({
  iconRetinaUrl,
  iconUrl,
  shadowUrl,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  tooltipAnchor: [16, -28],
  shadowSize: [41, 41]
});
L.Marker.prototype.options.icon = iconDefault;
*/




const colorsBivariate = {
  '31': '#64acbe', '32': '#627f8c', '33': '#574249',
  '21': '#b0d5df', '22': '#ad9ea5', '23': '#985356',
  '11': '#e8e8e8', '12': '#e4acac', '13': '#c85a5a',
}


const titlesBivariate = {
  '31': 'high {0}, low {1}', '32': 'high {0}, medium {1}', '33': 'high {0} and {1}',
  '21': 'medium {0}, low {1}', '22': 'medium {0} and {1}', '23': 'medium {0}, high {1}',
  '11': 'low {0} and {1}', '12': 'low {0}, medium {1}', '13': 'low {0}, high {1}',
}

const colorsUnivariate = ['#ccd8de', '#99b2bd', '#668b9d', '#33657c', '#003e5b'];

const formatString = (template, ...args) => {
  return template.replace(/{([0-9]+)}/g, function (match, index) {
    return typeof args[index] === 'undefined' ? match : args[index];
  });
}

@Component({
  selector: 'app-result-map',
  templateUrl: './result-map.component.html',
  styleUrl: './result-map.component.css'
})
export class ResultMapComponent implements OnInit, AfterViewInit, OnChanges {

  @Input() inputDisplayObject!: DisplayObject;
  @Input() inputDisplayDataUpdated!: boolean;

  @ViewChild(GraphComponent) childGraph: GraphComponent;


  mapLegendDiv: any;
  mapGraphDiv: any;

  private map;
  layerMapOSM: any;
  regionsLayer: any;
  xydata: any;
  displayType: string;
  popup: any;
  selectedArea:any;

  constructor(private featureService: FeatureService) {

  } // END CONSTRUCTOR

  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {
      // console.log('!!!!! !!!!! !!!!! !!!!! change in', propName, changes[propName].currentValue);
      const change = changes[propName];
      const valueCurrent = change.currentValue;
      // const valuePrevious = change.previousValue;
      if (propName === 'inputDisplayObject' && valueCurrent) {
        console.log('ngOnChanges(), "inputDisplayObject":', valueCurrent);
      }
      if (propName === 'inputDisplayDataUpdated') { //  && valueCurrent
        console.log('ngOnChanges(), "inputDisplayDataUpdated":', valueCurrent);

        this.changeResultMap();
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


    let graph = new LeafletControlGraph({position: 'topright'}).addTo(this.map);
    console.log('id=', graph.getContainer().id);
    this.mapGraphDiv = document.getElementById(graph.getContainer().id);
    this.mapGraphDiv.innerHTML += '<canvas id="myChart" width="400px" height="400px"></canvas>';

    this.hideLegend();
    this.hideGraph();

    new LeafletControlWatermark().addTo(this.map);

    let mapButtonsDivLeft = new LeafletControlMapButtonsLeft().addTo(this.map);
    // mapButtonsDivLeft.addButton(this.testToggle.bind(this), {id: 'mbl_0', mat_icon: 'near_me_disabled', title: 'start/stop navigatie', toggle: ['near_me', 'near_me_disabled']});
    mapButtonsDivLeft.addButton(this.zoomMapToFit.bind(this), {
      id: 'button_zoom_fit',
      class: 'map_button_zoom_fit',
      title: 'Show complete selection'
    });
    /*
    mapButtonsDivLeft.addButton(this.consoleLogData.bind(this), {
        id: 'button_zoom_fit',
        mat_icon: 'terminal',
        title: 'Log data in console ...'
    });
    */
    //this.addMouseClick();
    this.map.fitBounds(L.latLng(53.238, 6.536).toBounds(3000000));
  } // END FUNCTION initResultMap


  changeResultMap() {
    console.log('changeResultMap() ...');

    this.displayType = this.inputDisplayObject.displayType;


    // console.log(this.inputDisplayObject.tableFields[0].tableYear + ' ' + this.inputDisplayObject.tableFields[0].tableRegionLevel);
    // if (valueCurrent === true) {
    this.xydata = this.inputDisplayObject.displayData;

    if (this.regionsLayer !== undefined) {
      console.log('REMOVE regionsLayer');
      this.map.removeLayer(this.regionsLayer);

    }

    if (this.inputDisplayObject.displayData.length > 0) {
      this.regionsLayer = RegionsLayer.getLayer(this.inputDisplayObject.tableFields[0].tableRegionLevel, this.inputDisplayObject.tableFields[0].tableYear);
      if (typeof this.map !== 'undefined') {
        console.log('ADD regionsLayer');
        this.map.addLayer(this.regionsLayer);
      }
      this.plotData();
      this.childGraph.ScatterPlot( {'xlabel': this.legendLabel(this.inputDisplayObject.tableFields[0].tableDescr),
        'ylabel': this.legendLabel(this.inputDisplayObject.tableFields[1].tableDescr), 'xydata' : this.xydata});
    } else {
      //testdata
      // this.featureService.getRealXYData().subscribe((data) => {
      //   //console.log('data=', data);
      //   if (this.regionsLayer !== undefined) {
      //     this.map.removeLayer(this.regionsLayer);
      //   }
      //   this.regionsLayer = RegionsLayer.getLayer('2', '2016');
      //   this.map.addLayer(this.regionsLayer);
      //   this.xydata = data;
      //   this.plotData();
      //   this.setLegend({'type': 'bivariate','xlabel' : 'Deaths (Total)', 'ylabel' : 'Fertility Indicator'});
      //   this.childGraph.ScatterPlot({'xydata': data,'xlabel' : 'Deaths (Total)', 'ylabel' : 'Fertility Indicator'});
      // });
      // NO DATA NO LEGEND ...
      this.hideLegend();
    }

  } // END FUNCTION changeResultMap


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
    let result = this.xydata.reduce((map: { [x: string]: any; }, obj: { geo: string | number; }) => {
      map[obj.geo] = obj;
      return map;
    }, {})

    this.initLegend();

    switch (this.displayType) {
      case 'bivariate':
        this.changeMapStyleBivariate(result);
        this.showGraph();
        break;

      default:
        this.changeMapStyleUnivariate(result);
        break;
    }
    this.addMouseClick();
    this.addMouseOver(result);

  } // END FUNCTION plotData


  changeMapStyleUnivariate(mapdata: any) {
    let unknown = [];
    let xdata = this.xydata.map((item: any) => Number(item.x)).filter(Number);
    // console.log('UNI xdata:', xdata);
    let xmax = Math.max(...xdata);
    let xmin = Math.min(...xdata);
    console.log(xmin, xmax);
    this.regionsLayer.options.vectorTileLayerStyles.default = ((properties: any) => {
      let entity1 = 0;
      if (mapdata[properties['nuts_id']] != undefined) {
        entity1 = +mapdata[properties['nuts_id']].x;
      } else {
        unknown.push(properties['nuts_id']);
      }

      let fillColor = this.getColorUnivariate(entity1, xmin, xmax);
      return {
        fill: true, fillColor: fillColor, fillOpacity: 1,
        color: 'rgba(185,178,178,0.8)', opacity: 1, weight: 0.5,
      };
    })
    this.regionsLayer.redraw();

    this.setLegend({
      'type': 'univariate',
      'xlabel': this.inputDisplayObject.tableFields[0].tableDescr,
      'xmin': xmin,
      'xmax': xmax
    });

    console.log('nuts_ids not found', unknown);
  } // END FUNCTION changeMapStyleUnivariate

  getColorUnivariate(xvalue: number, xmin: number, xmax: number): any {
    //console.log('getColorUnivariate():', xvalue, xmin, xmax);

    let colorIndex = Math.floor((xvalue - xmin) / ((xmax - xmin) / colorsUnivariate.length));
    if (xvalue === 0) {
      return '#FFFFFF';
    }
    return colorsUnivariate[colorIndex];
  } // END FUNCTION getColorUnivariate


  changeMapStyleBivariate(mapdata: any) {
    let unknown = [];
    let xdata = this.xydata.map((item: any) => Number(item.x)).filter(Number);
    let ydata = this.xydata.map((item: any) => item.y).filter(Number);
    //console.log(xdata);
    //console.log('BI xdata:', xdata);
    //console.log('BI ydata:', ydata);
    let xmax = Math.max(...xdata);
    let ymax = Math.max(...ydata);
    let ymin = Math.min(...ydata);
    let xmin = Math.min(...xdata);
    console.log(xmin, xmax, ymin, ymax);
    this.regionsLayer.options.vectorTileLayerStyles.default = ((properties: any) => {
      if (properties['nuts_id'] === 'HR03') {
        console.log('properties', properties['nuts_id'], properties['nuts_name']);
      }
      let entity1 = 0;
      let entity2 = 0;
      if (mapdata[properties['nuts_id']] != undefined) {
        entity1 = +mapdata[properties['nuts_id']].x;
        entity2 = +mapdata[properties['nuts_id']].y;
      } else {
        unknown.push(properties['nuts_id']);
      }

      let fillColor = this.getColorBivariate(entity1, xmin, xmax, entity2, ymin, ymax);
      //console.log('fillColor', fillColor);
      //console.log('properties', properties);
      return {
        fill: true, fillColor: fillColor, fillOpacity: 1,
        color: 'rgba(185,178,178,0.8)', opacity: 1, weight: 0.5,
      };
    })
    this.regionsLayer.redraw();

    this.setLegend({
      'type': 'bivariate',
      'xlabel': this.inputDisplayObject.tableFields[0].tableDescr,
      'ylabel': this.inputDisplayObject.tableFields[1].tableDescr
    });

    console.log('nuts_ids not found', unknown);
  } // END FUNCTION changeMapStyleBivariate


  getColorBivariate(xvalue: number, xmin: number, xmax: number, yvalue: number, ymin: number, ymax: number): any {

    //console.log(xvalue, xmin, xmax, yvalue, ymin, ymax);

    let index1 = Math.ceil((xvalue - xmin) / ((xmax - xmin) / 3));
    let index2 = Math.ceil((yvalue - ymin) / ((ymax - ymin) / 3))
    if (xvalue === 17.2) {
      console.log(index1 + ' ' + index2);
    }


    if (xvalue === 0 && yvalue === 0) {
      return '#FFFFFF';
    }
    return colorsBivariate[index2.toString() + index1.toString()];
  } // END FUNCTION getColorBivariate


  addMouseOver(popupdata: any): any {
    this.regionsLayer.on('mouseover', ((event: { layer: { properties: any; }; latlng: L.LatLngExpression; }) => {
      //console.log('click', event);
      const properties = event.layer.properties;
      //console.log('properties', properties)
      if (properties) {
        //console.log('properties', properties['nuts_id']);

        let content = `<h3>${properties.nuts_name || 'Unknown'}</h3>`;  // Assume that your data might contain a "name" field
        content += '<div>' + JSON.stringify(properties) + '</div>';
        let entity1 = 'no data';
        if (popupdata[properties['nuts_id']] != 'null') {
          entity1 = popupdata[properties['nuts_id']].x;
        }
        let entity2 = 'no data';
        if (popupdata[properties['nuts_id']] != 'null') {
          entity2 = popupdata[properties['nuts_id']].y;
        }
        content += '<div>' + entity1 + '</div>';
        content += '<div>' + entity2 + '</div>';
        this.selectedArea = properties['nuts_id'];
        this.regionsLayer.setFeatureStyle(properties['nuts_id'], {default: {
            weight: 4,
            color: 'rgba(185,178,178,0.8)'
        }});
        this.childGraph.highlightPoint([{ x: entity1, y: entity2 }])
        // You can place the popup at the event latlng or on the layer.
        this.popup = L.popup()
          .setContent(content)
          .setLatLng(event.latlng)
          .openOn(this.map);
      } else {
        // L.popup().close();
      }

    }));

    this.regionsLayer.on('mouseout',  (event) => {
      this.map.closePopup(this.popup);
      this.regionsLayer.resetFeatureStyle(this.selectedArea);
    });
  }

  addMouseClick() : any {
    this.regionsLayer.on('click', ((event: { layer: { properties: any; }; latlng: L.LatLngExpression; }) => {

      const properties = event.layer.properties;
      if (properties) {
        console.log('clicked:' + properties['nuts_id']);
      }
      //L.DomEvent.stop(event);

    }));
  }


  hideLegend() {
    this.mapLegendDiv.style.display = 'none';

  } // END FUNCTION hideLegend

  initLegend() {
    this.mapLegendDiv.style.display = 'block';

    this.mapLegendDiv.innerHTML = '';
  } // END FUNCTION initLegend

  hideGraph() {
    this.mapGraphDiv.style.display = 'none';
  }

  showGraph() {
    this.mapGraphDiv.style.display = 'block';
  }

  setLegend(info): any {


    const legendType = info.type;

    console.log('setLegend()', legendType);


    // this.mapLegendDiv.innerHTML = '<h4>Legend</h4>';
    let legendHeader = document.createElement('h4');
    legendHeader.setAttribute('class', 'legendHeader');
    legendHeader.innerHTML = 'Legend';
    this.mapLegendDiv.appendChild(legendHeader);

    switch (legendType) {

      case 'univariate':
        this.uniVariateLegend(info);
        break;

      case 'bivariate':
        this.biVariateLegend(info);

        break;

      default:
        this.mapLegendDiv.innerHTML += 'unknown legend type \'' + legendType + '\'';

        break;
    } // END SWITCH legendType

  } // END FUNCTION setLegend

  private biVariateLegend(info: any) {
    const xmlns = 'http://www.w3.org/2000/svg';
    let svgWidth = 250;
    let svgHeight = 200;

    let containerSvg = document.createElementNS(xmlns, 'svg');
    this.mapLegendDiv.appendChild(containerSvg);
    containerSvg.setAttributeNS(null, 'class', 'legendSvgGraph');
    containerSvg.setAttributeNS(null, 'width', svgWidth.toString());
    containerSvg.setAttributeNS(null, 'height', svgHeight.toString());
    containerSvg.setAttributeNS(null, 'viewBox', '0 0 ' + svgWidth + ' ' + svgHeight);

    let bg = document.createElementNS(xmlns, 'rect');
    containerSvg.appendChild(bg);
    bg.setAttributeNS(null, 'fill', '#ffffff');
    bg.setAttributeNS(null, 'opacity', '0.5');
    bg.setAttributeNS(null, 'width', svgWidth.toString());
    bg.setAttributeNS(null, 'height', svgHeight.toString());
    // bg.addEventListener('mouseover', legendBlockMouseOut);

    for (let x = 1; x <= 3; x++) {
      for (let y = 1; y <= 3; y++) {
        // context.beginPath();
        // context.fillStyle = colorsBivariate[x.toString() + y.toString()];
        let blockPath = document.createElementNS(xmlns, 'path');
        containerSvg.appendChild(blockPath);
        let startX = Math.floor((svgWidth / 2) + (x * 26) - (y * 26));
        let startY = Math.floor(svgHeight + 35 - (x * 26) - (y * 26));

        let path = 'M ' + (startX).toString() + ' ' + (startY).toString() + ' L ' + (startX - 25).toString() + ' ' + (startY - 25).toString() + ' L ' + (startX).toString() + ' ' + (startY - 50).toString() + ' L ' + (startX + 25).toString() + ' ' + (startY - 25).toString() + ' z';
        blockPath.id = 'legendBlock_' + x.toString() + '_' + y.toString();
        blockPath.setAttributeNS(null, 'stroke', '#000000');
        blockPath.setAttributeNS(null, 'stroke-width', '2');
        blockPath.setAttributeNS(null, 'stroke-opacity', '0');
        blockPath.setAttributeNS(null, 'opacity', '1');
        blockPath.setAttributeNS(null, 'fill', colorsBivariate[y.toString() + x.toString()]);
        blockPath.setAttributeNS(null, 'd', path);
        blockPath.setAttributeNS(null, 'title',
          formatString(titlesBivariate[x.toString() + y.toString()], this.legendLabel(info.xlabel), this.legendLabel(info.ylabel)));

        blockPath.addEventListener('mouseover', legendBlockMouseOver);
        blockPath.addEventListener('mouseout', legendBlockMouseOut);


      }
    }

    let blockIndicator = document.createElementNS(xmlns, 'path');
    containerSvg.appendChild(blockIndicator);
    // let indicatorPath = 'M ' + (-100).toString() + ' ' + (-100).toString() + ' L ' + (-100 - 25).toString() + ' ' + (-100 - 25).toString() + ' L ' + (-100).toString() + ' ' + (-100 - 50).toString() + ' L ' + (-100 + 25).toString() + ' ' + (-100 - 25).toString() +' z';
    let indicatorPath = 'M -100 -100 L -125 -125 L -100 -150 L -75 -125 z';
    blockIndicator.id = 'legendBlockIndicator';
    blockIndicator.setAttributeNS(null, 'stroke', '#000000');
    blockIndicator.setAttributeNS(null, 'stroke-width', '2');
    blockIndicator.setAttributeNS(null, 'stroke-opacity', '1');
    blockIndicator.setAttributeNS(null, 'opacity', '1');
    blockIndicator.setAttributeNS(null, 'fill', '#ffffff');
    blockIndicator.setAttributeNS(null, 'fill-opacity', '0');
    blockIndicator.setAttributeNS(null, 'd', indicatorPath);


    let textPredictor = document.createElementNS(xmlns, 'text');
    containerSvg.appendChild(textPredictor);
    textPredictor.setAttributeNS(null, 'x', Math.floor(3 * svgWidth / 4).toString());
    textPredictor.setAttributeNS(null, 'y', Math.floor(3 * svgHeight / 4).toString());
    textPredictor.setAttributeNS(null, 'fill', '#000000');
    textPredictor.setAttributeNS(null, 'text-anchor', 'middle');
    textPredictor.setAttributeNS(null, 'font-weight', 'bold');
    textPredictor.setAttributeNS(null, 'font-size', '12px');
    textPredictor.setAttributeNS(null, 'transform', 'rotate(-45, ' + Math.floor(3 * svgWidth / 4).toString() + ', ' + Math.floor(3 * svgHeight / 4).toString() + ')');
    textPredictor.innerHTML = this.legendLabel(info.xlabel )+ ' &#11166;';

    let textOutcome = document.createElementNS(xmlns, 'text');
    containerSvg.appendChild(textOutcome);
    textOutcome.setAttributeNS(null, 'x', Math.floor(1 * svgWidth / 4).toString());
    textOutcome.setAttributeNS(null, 'y', Math.floor(3 * svgHeight / 4).toString());
    textOutcome.setAttributeNS(null, 'fill', '#000000');
    textOutcome.setAttributeNS(null, 'text-anchor', 'middle');
    textOutcome.setAttributeNS(null, 'font-weight', 'bold');
    textOutcome.setAttributeNS(null, 'font-size', '12px');
    textOutcome.setAttributeNS(null, 'transform', 'rotate(45, ' + Math.floor(1 * svgWidth / 4).toString() + ', ' + Math.floor(3 * svgHeight / 4).toString() + ')');
    textOutcome.innerHTML = '&#11164; ' + this.legendLabel(info.ylabel);


    let textExplain = document.createElementNS(xmlns, 'text');
    containerSvg.appendChild(textExplain);
    textExplain.id = 'legendTextExplain';
    textExplain.setAttributeNS(null, 'x', Math.floor(1 * svgWidth / 2).toString());
    textExplain.setAttributeNS(null, 'y', '14');
    textExplain.setAttributeNS(null, 'fill', '#000000');
    textExplain.setAttributeNS(null, 'text-anchor', 'middle');
    //textExplain.setAttributeNS(null, 'font-weight', 'bold');
    textExplain.setAttributeNS(null, 'font-style', 'italic');
    textExplain.setAttributeNS(null, 'font-size', '12px');
    textExplain.setAttributeNS(null, 'height', '4em');
    textExplain.innerHTML = 'Select a color to see its meaning';
  }

  private uniVariateLegend(info: any) {
    let colorStep = ((info.xmax - info.xmin) / colorsUnivariate.length);
    let colorsUnivariateReverse = colorsUnivariate.slice().reverse();

    let toFixedNumber = 0;
    if (colorStep < 10) {
      toFixedNumber = 1;
      if (colorStep < 1) {
        toFixedNumber = 2;
        if (colorStep < 0.1) {
          toFixedNumber = 3;
        }
      }
    }

    colorsUnivariateReverse.forEach((color, index) => {
      let indexReverseFrom = colorsUnivariate.length - index - 1;
      let indexReverseTo = colorsUnivariate.length - index;
      // this.mapLegendDiv.innerHTML += '<div class="legendColorBlock" style="background-color: ' + color + '"></div> ' + (info.xmin + (colorStep * indexReverseFrom)).toFixed(toFixedNumber) + ' - ' + (info.xmin + (colorStep * indexReverseTo)).toFixed(toFixedNumber) + '<br>\n';

      let legendLine = document.createElement('div');
      legendLine.setAttribute('class', 'legendLine');
      this.mapLegendDiv.appendChild(legendLine);

      let legendBlock = document.createElement('div');
      legendBlock.setAttribute('class', 'legendColorBlock');
      legendBlock.style.backgroundColor = color;
      legendLine.appendChild(legendBlock);

      let legendText = document.createElement('div');
      legendText.setAttribute('class', 'legendColorText');
      legendText.innerHTML = (info.xmin + (colorStep * indexReverseFrom)).toFixed(toFixedNumber) + ' - ' + (info.xmin + (colorStep * indexReverseTo)).toFixed(toFixedNumber);
      legendLine.appendChild(legendText);


    });
  }


  legendLabel(text: string): string {
    let label = '';
    let textparts = text.split(' ');
    if (textparts.length > 1) {
      label = textparts[0] + ' ' + textparts[1].replace('by', '');
    }
    return label;
  }

}


function legendBlockMouseOver(e) {
  //console.log('legendBlockMouseOver(), event:', e.target.id);

  document.getElementById(e.target.id).setAttributeNS(null, 'stroke-opacity', '1');

  //console.log('TEST:', document.getElementById(e.target.id).getAttributeNS(null, 'd'));
  // document.getElementById('legendBlockIndicator').setAttributeNS(null, 'd', document.getElementById(e.target.id).getAttributeNS(null, 'd') );

  document.getElementById('legendTextExplain').innerHTML = document.getElementById(e.target.id).getAttributeNS(null, 'title');

} // END FUNCTION legendBlockMouseOver

function legendBlockMouseOut(e) {
  //console.log('legendBlockMouseOut(), event:', e.target.id);
  document.getElementById(e.target.id).setAttributeNS(null, 'stroke-opacity', '0');

  // document.getElementById('legendBlockIndicator').setAttributeNS(null, 'd', 'M -100 -100 L -125 -125 L -100 -150 L -75 -125 z' );

  document.getElementById('legendTextExplain').innerHTML = '';

} // END FUNCTION legendBlockMouseOut
