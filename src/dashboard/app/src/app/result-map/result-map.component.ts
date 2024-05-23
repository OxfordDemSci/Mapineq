import {AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges} from '@angular/core';
import * as L from "leaflet";

import 'leaflet.vectorgrid/dist/Leaflet.VectorGrid.bundled.js';

import {FeatureService} from "../services/feature.service";
import {RegionsLayer} from "../layers/regions-layer";
import {DisplayObject} from "../lib/display-object";
import {
    LeafletControlLegend,
    LeafletControlMapButtonsLeft,
    LeafletControlWatermark
} from "../lib/leaflet-control-custom";


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

const colorsUnivariate = ['#ccd8de', '#99b2bd', '#668b9d', '#33657c', '#003e5b'];


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
    displayType: string;

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
        this.hideLegend();


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

        } else {
            // NO DATA NO LEGEND ...
            this.hideLegend();
        }


        // } else {
        // this.featureService.getRealXYData().subscribe((data) => {
        //   //console.log('data=', data);
        //   if (this.regionsLayer !== undefined) {
        //     this.map.removeLayer(this.regionsLayer);
        //   }
        //   this.regionsLayer = RegionsLayer.getLayer('2', '2016');
        //   this.map.addLayer(this.regionsLayer);
        //   this.xydata = data;
        //   this.plotData();
        //   this.addLegend({'xlabel' : 'Deaths (Total)', 'ylabel' : 'Fertility Indicator'});
        // });
        // }

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
        console.log('plotData() ...', this.displayType);


        let result = this.xydata.reduce((map: { [x: string]: any; }, obj: { geo: string | number; }) => {
            map[obj.geo] = obj;
            return map;
        }, {})
        console.log('AT11', result['AT11']);
        console.log('FI1D7', result['FI1D7']);

        this.initLegend();
        switch(this.displayType) {
            case 'bivariate':
                this.changeMapStyleBivariate(result);
                break;

            default:
                this.changeMapStyleUnivariate(result);
                break;
        }

        this.addMouseOver(result);
    } // END FUNCTION plotData


    changeMapStyleUnivariate(mapdata: any) {
        let unknown = [];
        let xdata = this.xydata.map((item: any) => Number(item.x));
        // console.log('UNI xdata:', xdata);
        let xmax = Math.max(...xdata);
        let xmin = Math.min(...xdata);
        // console.log(xmin, xmax);
        this.regionsLayer.options.vectorTileLayerStyles.default = ((properties: any) => {
            let entity1 = 0;
            if (mapdata[properties['nuts_id']] != undefined) {
                entity1 = +mapdata[properties['nuts_id']].x;
            } else {
                unknown.push(properties['nuts_id']);
            }

            let fillColor = this.getColorUnivariate(entity1, xmin, xmax);
            //console.log('fillColor', fillColor);
            //console.log('properties', properties);
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
        let xdata = this.xydata.map((item: any) => Number(item.x));
        let ydata = this.xydata.map((item: any) => item.y);
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



    hideLegend() {
        this.mapLegendDiv.style.display = 'none';
    } // END FUNCTION hideLegend

    initLegend() {
        this.mapLegendDiv.style.display = 'block';

        this.mapLegendDiv.innerHTML = '';
        
        // this.mapLegendDiv.innerHTML = '<h4>Legend</h4>';
        // this.mapLegendDiv.innerHTML += '<img id="scream" alt="legenda"  style="display:none" src="assets/img/legend.png"></img>';
        // this.mapLegendDiv.innerHTML += '<canvas id="myCanvas" width="190" height="180" ></canvas>';

    } // END FUNCTION initLegend


    setLegend(info): any {

        const legendType = info.type;

        console.log('setLegend()', legendType);


        this.mapLegendDiv.innerHTML = '<h4>Legend</h4>';

        switch (legendType) {

            case 'univariate':
                // <div class="col"

                // let colorIndex = Math.floor((xvalue - xmin) / ((xmax - xmin) / colorsUnivariate.length));
                let colorStep = ((info.xmax - info.xmin) / colorsUnivariate.length);

                let colorsUnivariateReverse = colorsUnivariate.slice().reverse();

                let toFixedNumber = 0;
                if (colorStep < 10) {
                    toFixedNumber = 1;
                    if (colorStep < 1) {
                        toFixedNumber = 2;
                    }
                }

                colorsUnivariateReverse.forEach( (color, index) => {
                    let indexReverseFrom = colorsUnivariate.length - index - 1;
                    let indexReverseTo = colorsUnivariate.length - index;
                    this.mapLegendDiv.innerHTML += '<div class="legendColorBlock" style="background-color: ' + color + '"></div> ' + (info.xmin + (colorStep * indexReverseFrom)).toFixed(toFixedNumber) + ' - ' + (info.xmin + (colorStep * indexReverseTo)).toFixed(toFixedNumber) + '<br>\n';
                });


                break;

            case 'bivariate':
                this.mapLegendDiv.innerHTML += '<canvas id="myCanvas" width="190" height="180" ></canvas>';

                const boxsize = 50;
                const canvas = document.getElementById("myCanvas") as (HTMLCanvasElement);
                const context = canvas.getContext("2d");
                context.clearRect(0, 0, canvas.width, canvas.height);
                context.font = "11px Verdana";
                let textparts = info.xlabel.split(" ");
                context.fillText(textparts[0] + ' ' + textparts[1], 25, 180);
                const img = document.getElementById("scream") as HTMLImageElement;
                //context.drawImage(img, 15, 0, 180, 180);
                for (let x = 1; x <= 3; x++) {
                    for (let y = 1; y <= 3; y++) {
                        context.beginPath();
                        context.fillStyle = colorsBivariate[x.toString() + y.toString()];
                        context.fillRect(25 + (x - 1) * boxsize, 110 - ((y - 1) * boxsize), boxsize, boxsize);
                        context.stroke();
                    }

                }
                context.save();
                context.rotate(-90 * Math.PI / 180);
                context.translate(-180, 0)
                textparts = info.ylabel.split(" ");
                context.fillText(textparts[0] + ' ' + textparts[1], 20, 10);
                context.restore();
                break;

            default:
                this.mapLegendDiv.innerHTML += 'unknown legend type \'' + legendType + '\'';

                break;
        } // END SWITCH legendType

    } // END FUNCTION setLegend


}
