import {AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges, ViewChild} from '@angular/core';
// import 'leaflet/dist/leaflet.js';
import * as L from "leaflet";

/*
// import 'leaflet-easyprint/dist/bundle.js';
// import 'leaflet-easyprint';
// import easyPrint from "leaflet-easyprint";
import 'leaflet-easyprint';
*/

import 'leaflet.vectorgrid/dist/Leaflet.VectorGrid.bundled.js';


import {FeatureService} from "../services/feature.service";
import {RegionsLayer} from "../layers/regions-layer";
import {DisplayObject} from "../lib/display-object";
import {
    LeafletControlLegend,
    LeafletControlMapButtonsLeft,
    LeafletControlWatermark
} from "../lib/leaflet-control-custom";
import {GraphComponent} from "../graph/graph.component";
import {LeafletControlInfo} from "../lib/leaflet-control-info";
import {LeafletControlGraph} from "../lib/leaflet-control-graph";


import html2canvas from "html2canvas";
import {MatSnackBar} from "@angular/material/snack-bar";


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


// @ts-ignore
L.DomEvent.fakeStop = function () {
    return true;
}


const colorsBivariate = {
    '31': '#64acbe', '32': '#627f8c', '33': '#574249',
    '21': '#b0d5df', '22': '#ad9ea5', '23': '#985356',
    '11': '#e8e8e8', '12': '#e4acac', '13': '#c85a5a',
}

/*
const titlesBivariate = {
  '31': 'high {0}, low {1}', '32': 'high {0}, medium {1}', '33': 'high {0} and {1}',
  '21': 'medium {0}, low {1}', '22': 'medium {0} and {1}', '23': 'medium {0}, high {1}',
  '11': 'low {0} and {1}', '12': 'low {0}, medium {1}', '13': 'low {0}, high {1}',
}
*/
const titlesBivariate = {
    '31': '{0}: HIGH   | {1}: LOW', '32': '{0}: HIGH   | {1}: MEDIUM', '33': '{0}: HIGH   | {1}: HIGH',
    '21': '{0}: MEDIUM | {1}: LOW', '22': '{0}: MEDIUM | {1}: MEDIUM', '23': '{0}: MEDIUM | {1}: HIGH',
    '11': '{0}: LOW    | {1}: LOW', '12': '{0}: LOW    | {1}: MEDIUM', '13': '{0}: LOW    | {1}: HIGH',
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
    @Input() inputDisplayData!: any[];
    @Input() inputDisplayDataUpdated!: boolean;

    @ViewChild(GraphComponent) childGraph: GraphComponent;


    mapLegendDiv: any;

    mapGraphDiv: any;
    mapGraphContainer: any;
    graphOpen: boolean;

    mapInfoDiv: any;
    mapInfoContainer: any;
    infoOpen: boolean;

    regionsColor: any = {};


    private map;
    layerMapOSM: any;
    regionsLayer: any;
    xydata: any;
    displayType: string;
    popup: any;
    selectedArea: any;
    oldhighligth: string  = '';


    takingScreenshot: boolean;

    constructor(private featureService: FeatureService, private snackBar: MatSnackBar) {
        this.graphOpen = false;
        this.infoOpen = false;

        this.inputDisplayData = [];

        this.takingScreenshot = false;
    } // END CONSTRUCTOR

    ngOnChanges(changes: SimpleChanges) {
        for (const propName in changes) {
            // console.log('!!!!! !!!!! !!!!! !!!!! change in', propName, changes[propName].currentValue);
            const change = changes[propName];
            const valueCurrent = change.currentValue;
            // const valuePrevious = change.previousValue;
            if (propName === 'inputDisplayObject' && valueCurrent) {
                // console.log('ngOnChanges(), "inputDisplayObject":', valueCurrent);
            }
            if (propName === 'inputDisplayData' && valueCurrent) {
                // console.log('before abc  RESULT-MAP ngOnChanges(), "inputDisplayData":', valueCurrent);
                this.changeResultMap();
            }
            if (propName === 'inputDisplayDataUpdated') { //  && valueCurrent
                // console.log('before abc  RESULT-MAP ngOnChanges(), "inputDisplayDataUpdated":', valueCurrent);
                // if (typeof this.inputDisplayData !== 'undefined') {
                //     this.changeResultMap();
                // }
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

        new LeafletControlLegend({position: 'bottomright'}).addTo(this.map);
        this.mapLegendDiv = document.getElementById('map_legend_div');


        let mapGraphControl = new LeafletControlGraph({position: 'topright'}).addTo(this.map);
        mapGraphControl.addToggleButton(this.toggleMapGraph.bind(this));

        // console.log('id=', graph.getContainer().id);
        // this.mapGraphDiv = document.getElementById(graph.getContainer().id);
        this.mapGraphContainer = document.getElementById('map_graph_div');
        this.mapGraphDiv = document.getElementById('map_graph_div_graph');
        this.mapGraphDiv.innerHTML += '<canvas id="myChart" width="400px" height="400px"></canvas>';


        let mapInfoControl = new LeafletControlInfo({position: 'topright'}).addTo(this.map);
        //this.mapInfoDiv = document.getElementById(mapInfoControl.getContainer().id);
        mapInfoControl.addToggleButton(this.toggleMapInfo.bind(this));
        this.mapInfoContainer = document.getElementById('map_info_div');
        this.mapInfoDiv = document.getElementById('map_info_div_info');

        this.hideLegend();
        this.hideMapGraph();
        this.hideMapInfo();

        new LeafletControlWatermark().addTo(this.map);

        let mapButtonsDivLeft = new LeafletControlMapButtonsLeft().addTo(this.map);
        // mapButtonsDivLeft.addButton(this.testToggle.bind(this), {id: 'mbl_0', mat_icon: 'near_me_disabled', title: 'start/stop navigatie', toggle: ['near_me', 'near_me_disabled']});
        mapButtonsDivLeft.addButton(this.zoomMapToFit.bind(this), {
            id: 'button_zoom_fit',
            class: 'map_button_zoom_fit',
            title: 'Show complete selection'
        });

        mapButtonsDivLeft.addButton(this.saveMapToImage.bind(this), {
            id: 'button_screenshot',
            mat_icon: 'screenshot_monitor',
            title: 'Save map as image'
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


    toggleMapGraph(): void {
        console.log('toggleMapGraph() ...');
        this.graphOpen = !this.graphOpen;
        if (this.graphOpen) {
            document.getElementById('map_graph_div_toggle_button').className = 'graphToggleContainerButtonRight';
            document.getElementById('map_graph_div_graph_container').style.width = '420px';
            //document.getElementById('map_graph_div_graph_container').style.height = '400px';
        } else {
            document.getElementById('map_graph_div_toggle_button').className = 'graphToggleContainerButtonLeft';
            document.getElementById('map_graph_div_graph_container').style.width = '0px';
            //document.getElementById('map_graph_div_graph_container').style.height = '400px';
        }

    } // END FUNCTION toggleMapGraph

    toggleMapInfo() {
        console.log('toggleMapInfo() ...');

        this.infoOpen = !this.infoOpen;
        if (this.infoOpen) {
            document.getElementById('map_info_div_toggle_button').className = 'graphToggleContainerButtonRight';
            document.getElementById('map_info_div_info_container').style.width = '420px';
        } else {
            document.getElementById('map_info_div_toggle_button').className = 'graphToggleContainerButtonLeft';
            document.getElementById('map_info_div_info_container').style.width = '0px';
        }

    } // END FUNCTION toggleMapInfo

    closeMapInfo() {
        // this.mapInfoDiv.style.display = 'none';
        this.infoOpen = false;
        document.getElementById('map_info_div_toggle_button').className = 'graphToggleContainerButtonLeft';
        document.getElementById('map_info_div_info_container').style.width = '0px';

    } // END FUNCTION closeMapInfo

    openMapInfo() {
        // this.mapInfoDiv.style.display = 'block';
        this.infoOpen = true;
        document.getElementById('map_info_div_toggle_button').className = 'graphToggleContainerButtonRight';
        document.getElementById('map_info_div_info_container').style.width = '420px';

    } // END FUNCTION openMapInfo

    regionLayerMouseInfo(event) {
        // console.log('REGIONS LAYER, event: ', event, event.originalEvent.clientX, event.originalEvent.clientY, event.type);


        // this.regionsLayer.setFeatureStyle(properties['nuts_id'], {default: {
        this.regionsLayer.setFeatureStyle(event.layer.properties['nuts_id'], {
            default: {
                weight: 3,
                color: 'rgba(255,192,0,1)',
                fillColor: event.layer.options.fillColor,
                fill: true,
                fillOpacity: 1,
            }
        });

        let layer = event.layer;
        layer.bringToFront();

        // this.childGraph.highlightPoint([{ x: entity1, y: entity2 }]);
        //this.childGraph.highlightPoint([{ x: 0, y: 85}]);
        if (this.inputDisplayObject.displayType === 'bivariate' && ['mouseover', 'click'].includes(event.type)) {
            this.childGraph.highlightPointById(event.layer.properties['nuts_id']);
        }


        // let regionValues = this.inputDisplayObject.displayData.find(item => {
        let regionValues = this.inputDisplayData.find(item => {
            return item.geo === event.layer.properties['nuts_id'];
        }) ?? {};
        // console.log('REGIONS LAYER info: ', event.layer.properties['nuts_id'], regionValues);

        let dataHtml = '';
        if (this.inputDisplayObject.displayType === 'bivariate') {
            dataHtml += this.legendLabel(this.inputDisplayObject.tableFields[0].tableDescr) + ': ' + (regionValues.x ?? 'EMPTY').toString() + '<br>';
            dataHtml += this.legendLabel(this.inputDisplayObject.tableFields[1].tableDescr) + ': ' + (regionValues.y ?? 'EMPTY').toString() + '<br>';
        } else {
            dataHtml += this.legendLabel(this.inputDisplayObject.tableFields[this.inputDisplayObject.displayTableId].tableDescr) + ': ' + (regionValues.x ?? 'EMPTY').toString() + '<br>';
        }


        document.getElementById('gd_map_cursor_title').innerHTML = event.layer.properties['nuts_name'] + ' (' + event.layer.properties['nuts_id'] + ')';
        document.getElementById('gd_map_cursor_data').innerHTML = dataHtml;
        // document.getElementById('gd_map_cursor_graph').innerHTML = 'test-graph';


        // let mapLeft = document.getElementById('resultMap').offsetLeft;
        let mapLeft = document.getElementById('drawerRight').offsetWidth;
        let mapTop = document.getElementById('matDrawerContainer').offsetTop;
        let mapWidth = document.getElementById('resultMap').offsetWidth;
        let mapHeight = document.getElementById('resultMap').offsetHeight;

        // console.log('SIZES:', mapLeft, mapTop, mapWidth, mapHeight);

        let cursorX = event.originalEvent.clientX;
        let cursorY = event.originalEvent.clientY;

        let infoX = cursorX - mapLeft; // + 20;
        let infoY = cursorY - mapTop;
        if (infoX > mapWidth / 2) {
            infoX = Math.max(infoX - 80 - document.getElementById('gd_map_cursor_info').offsetWidth, 10);
        } else {
            infoX = Math.min(infoX + 80, mapWidth - 10 - document.getElementById('gd_map_cursor_info').offsetWidth);
        }
        if (infoY > mapHeight / 2) {
            infoY = Math.min(infoY - (document.getElementById('gd_map_cursor_info').offsetHeight / 2), mapHeight - document.getElementById('gd_map_cursor_info').offsetHeight - 10);
        } else {
            infoY = Math.max(10, infoY - (document.getElementById('gd_map_cursor_info').offsetHeight / 2));
        }

        document.getElementById('gd_map_cursor_info').style.left = (infoX).toString() + 'px';
        document.getElementById('gd_map_cursor_info').style.top = (infoY).toString() + 'px';


        document.getElementById('gd_map_cursor_info').style.display = 'block';

    } // END FUNCTION regionLayerMouseInfo

    regionLayerMouseInfoClose(event) {
        // console.log('REGIONS LAYER, event (CLOSE): ', event);

        this.childGraph.removehighlight();

        document.getElementById('gd_map_cursor_info').style.display = 'none';

        this.regionsLayer.resetFeatureStyle(event.layer.properties['nuts_id']);

    } // END FUNCTION regionLayerMouseInfoClose


    changeResultMap() {
        // console.log('changeResultMap() ...');

        this.displayType = this.inputDisplayObject.displayType;
        // console.log('changeResultMap() ...', this.displayType);

        // console.log(this.inputDisplayObject.tableFields[0].tableYear + ' ' + this.inputDisplayObject.tableFields[0].tableRegionLevel);
        // if (valueCurrent === true) {
        // this.xydata = this.inputDisplayObject.displayData;
        this.xydata = this.inputDisplayData;


        if (this.regionsLayer !== undefined) {
            //console.log('REMOVE regionsLayer');
            this.map.removeLayer(this.regionsLayer);
            this.hideMapGraph();
        }

        // if (this.inputDisplayObject.displayData.length > 0) {
        if (this.inputDisplayData.length > 0) {
            // this.regionsLayer = RegionsLayer.getLayer(this.inputDisplayObject.tableFields[0].tableRegionLevel, this.inputDisplayObject.tableFields[0].tableYear);
            console.log('Check selected year/best year:', this.inputDisplayObject.tableFields[0].tableYear, '/', this.inputDisplayData[0].best_year);
            this.regionsLayer = RegionsLayer.getLayer(this.inputDisplayObject.tableFields[0].tableRegionLevel, this.inputDisplayData[0].best_year);
            if (typeof this.map !== 'undefined') {
                //console.log('ADD regionsLayer');
                this.map.addLayer(this.regionsLayer);
            }
            /*
            this.regionsLayer.on('click', (event) => {
              console.log('click REGIONS LAYER: ', event);
            });
            */
            this.regionsLayer.on({
                click: this.regionLayerMouseInfo.bind(this),
                mouseover: this.regionLayerMouseInfo.bind(this),
                mousemove: this.regionLayerMouseInfo.bind(this),
                mouseout: this.regionLayerMouseInfoClose.bind(this)
            });


            this.plotData();
            this.childGraph.ScatterPlot({
                'xlabel': this.legendLabel(this.inputDisplayObject.tableFields[0].tableDescr),
                'ylabel': this.legendLabel(this.inputDisplayObject.tableFields[1].tableDescr), 'xydata': this.xydata
            });
            this.setInfoSelections();
        } else {
            this.hideLegend();
            this.hideMapInfo();
        }

    } // END FUNCTION changeResultMap

    setInfoSelections(): void {
        console.log();
        let html = '<table class="selections">';
        html += '<tr>';
        if (this.displayInfo(0)) {
            html += '<th>' + this.legendLabel(this.inputDisplayObject.tableFields[0].tableDescr) + '</th>'
        }
        if (this.displayInfo(1)) {
            html += '<th>' + this.legendLabel(this.inputDisplayObject.tableFields[1].tableDescr) + '</th>'
        }
        html += '</tr>';
        html += '<tr>';
        if (this.displayInfo(0)) {
            html += '<td class="selectionsvalues">';
            //first table
            html += this.setInfoSelectionsKeyvalues(this.inputDisplayObject.tableFields[0].Selections);
            html += '</td>';
        }
        if (this.displayInfo(1)) {
            html += '<td class="selectionsvalues">';
            //second table
            html += this.setInfoSelectionsKeyvalues(this.inputDisplayObject.tableFields[1].Selections);
            html += '</td>';
        }
        html += '</tr>';
        html += '</table>'
        this.mapInfoDiv.innerHTML = html;
        // this.openMapInfo();
        this.showMapInfo();
    }

    displayInfo(tableId: number): Boolean {
        if (this.inputDisplayObject.displayType === 'univariate') {
            return this.inputDisplayObject.displayTableId === tableId;
        } else {
            return true;
        }
    }

    setInfoSelectionsKeyvalues(Selections: any) : string {
        //console.log('Selections', Selections);
        if (Selections === undefined) { return '';}
        let html = '<table class="selections">';
        Object.keys(Selections).forEach((key) => {
            html += '<tr>'
            html += '<td class="selectionsvalues">';
            html += key;
            html += ':</td>';
            html += '<td class="selectionsvalues">';
            html += Selections[key];
            html += '</td>';
            html += '</tr>';
        })

        html += '</table>'
        return html;
    }

    resizeMap(): void {
        // console.log('TEST: ', document.getElementById('map').offsetWidth);

        this.map.invalidateSize(true);
        // this.layerMap.redraw();

    } // END FUNCTION resizeMap


    public zoomMapToFit(): void {
        // this.map.fitBounds(this.regionsLayer.getBounds());
        this.map.fitBounds(L.latLng(53.238, 6.536).toBounds(3000000));
    } // END FUNCTION zoomMapToFit


    public saveMapToImage() {
        console.log('saveMapToImage() ...');

        if (!this.takingScreenshot) {

            document.getElementById('button_screenshot').style.display = 'none';
            this.takingScreenshot = true;

            // this.openSnack('Creating image of map, please wait');


            let print_date = new Date();

            let time_string = print_date.getFullYear() + '' + ('00' + (print_date.getMonth() + 1)).substr(-2) + '' + ('00' + print_date.getDate()).substr(-2);
            time_string += '_' + ('00' + print_date.getHours()).substr(-2) + '' + ('00' + print_date.getMinutes()).substr(-2) + '' + ('00' + print_date.getSeconds()).substr(-2);

            let img_filename = time_string + '_mapineq.png';

            // button_screenshot button_zoom_fit map_graph_div_toggle map_info_div_toggle
            // leaflet-control-zoom
            let zoomButtons = document.getElementsByClassName('leaflet-control-zoom');
            for (let i = 0; i < zoomButtons.length; i++) {
                zoomButtons[i].setAttribute('data-html2canvas-ignore', 'true');
            }
            /* /
            let attributionDivs = document.getElementsByClassName('leaflet-control-attribution');
            for (let i = 0; i < attributionDivs.length; i++) {
                attributionDivs[i].setAttribute('data-html2canvas-ignore', 'true');
            }
            /* */
            document.getElementById('button_zoom_fit').setAttribute('data-html2canvas-ignore', 'true');
            document.getElementById('button_screenshot').setAttribute('data-html2canvas-ignore', 'true');
            document.getElementById('map_graph_div_toggle').setAttribute('data-html2canvas-ignore', 'true');
            document.getElementById('map_info_div_toggle').setAttribute('data-html2canvas-ignore', 'true');
            /* /
            document.getElementById('map_legend_div').setAttribute('data-html2canvas-ignore', 'true');
            /* */

            // Select the element that you want to capture
            // const captureElement = document.querySelector("#capture");
            const captureElement = document.getElementById('resultMap');

            // Call the html2canvas function and pass the element as an argument
            html2canvas(captureElement, {allowTaint: true, useCORS: true}).then((canvas) => {
                // Get the image data as a base64-encoded string
                const imageData = canvas.toDataURL("image/png");

                // Do something with the image data, such as saving it as a file or sending it to a server
                // For example, you can create an anchor element and trigger a download action
                const link = document.createElement("a");
                link.setAttribute("download", img_filename);
                link.setAttribute("href", imageData);
                link.click();

                this.takingScreenshot = false;
                document.getElementById('button_screenshot').style.display = 'block';
            });


        }
        /*
        let customSize = {
            width: document.getElementById('resultMap').offsetWidth,
            height: document.getElementById('resultMap').offsetHeight,
            className: "doesnt-matter",
            name: "doesnt-matter"
        };

        console.log('just before (L as any).easyPrint / L.easyPrint ...');
        let printPlugin = (L as any).easyPrint({
        // @ts-ignore
        //let printPlugin = L.easyPrint({
            hidden: true,
            exportOnly: true,
            hideControlContainer: false,
            hideClasses: ['leaflet-control-zoom', 'map_button', 'map_button_mat_icon', 'graphToggleContainerRight', 'panelToggleContainerRight'],
            sizeModes: [customSize]
        }).addTo(this.map);

        printPlugin.printMap(customSize.name, time_string+'_mapineq');
        */

    } // END FUNCTION saveMapToImage



    public consoleLogData() {
        console.log('Current inputDisplayObject.displayData:', this.inputDisplayObject.displayData);
        console.log('Current inputDisplayData:', this.inputDisplayData);
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
                this.showMapGraph();
                break;

            default:
                this.changeMapStyleUnivariate(result);
                this.hideMapGraph();
                break;
        }
        // this.addMouseClick(result);
        // this.addMouseOver(result);

    } // END FUNCTION plotData


    changeMapStyleUnivariate(mapdata: any) {
        let unknown = [];
        let xdata = this.xydata.map((item: any) => Number(item.x)).filter(Number);
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
        if (xvalue === xmax) {
            colorIndex = (colorsUnivariate.length - 1);
        }

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
        //console.log(xmin, xmax, ymin, ymax);
        this.regionsLayer.options.vectorTileLayerStyles.default = ((properties: any) => {
            let entity1 = 0;
            let entity2 = 0;
            if (mapdata[properties['nuts_id']] != undefined) {
                entity1 = +mapdata[properties['nuts_id']].x;
                entity2 = +mapdata[properties['nuts_id']].y;
            } else {
                unknown.push(properties['nuts_id']);
            }

            let fillColor = this.getColorBivariate(entity1, xmin, xmax, entity2, ymin, ymax);
            this.regionsColor[properties['nuts_id']] = fillColor;
            //console.log('fillColor', fillColor);
            //console.log('properties', properties);

            // if (properties['nuts_id'] === 'PL41') {
            //   console.log('CHECK WAARDEN:', properties['nuts_id'], fillColor, mapdata[properties['nuts_id']].x, mapdata[properties['nuts_id']].y, xmin, xmax, ymin, ymax);
            // }
            return {
                fill: true, fillColor: fillColor, fillOpacity: 1,
                // color: 'rgba(185,178,178,0.8)', opacity: 1, weight: 0.5,
                color: 'rgb(185,178,178)', opacity: 1, weight: 0.5,
            };
        })
        this.regionsLayer.redraw();

        this.setLegend({
            'type': 'bivariate',
            'xlabel': this.inputDisplayObject.tableFields[0].tableDescr,
            'ylabel': this.inputDisplayObject.tableFields[1].tableDescr
        });

        //console.log('nuts_ids not found', unknown);
    } // END FUNCTION changeMapStyleBivariate


    getColorBivariate(xvalue: number, xmin: number, xmax: number, yvalue: number, ymin: number, ymax: number): any {
        //console.log('xvalue, xmin, xmax, yvalue, ymin, ymax',xvalue, xmin, xmax, yvalue, ymin, ymax);

        if (xvalue === undefined || yvalue === undefined || typeof xvalue === 'undefined' || typeof yvalue === 'undefined' || xvalue === 0 || yvalue === 0 || xvalue === null || yvalue === null) {
            return '#FFFFFF';
        }

        let index1 = Math.max(Math.ceil((xvalue - xmin) / ((xmax - xmin) / 3)), 1);
        let index2 = Math.max(Math.ceil((yvalue - ymin) / ((ymax - ymin) / 3)), 1);

        return colorsBivariate[index2.toString() + index1.toString()];
    } // END FUNCTION getColorBivariate


    addMouseOver(popupdata: any): any {
        this.regionsLayer.on('mouseover', ((event: { layer: { properties: any; }; latlng: L.LatLngExpression; }) => {
            //console.log('click', event);
            const properties = event.layer.properties;
            //console.log('properties', properties)
            if (properties) {
                this.selectedArea = properties['nuts_id'];
                //console.log('properties', properties['nuts_id']);
                let content = `<h3>${properties.nuts_name || 'Unknown'} (${properties.nuts_id})</h3>`;  // Assume that your data might contain a "name" field
                let entity1 = 'no data';
                if (popupdata[properties['nuts_id']] != 'null') {
                    entity1 = popupdata[properties['nuts_id']].x;
                }
                let entity2 = 'no data';
                if (popupdata[properties['nuts_id']] != 'null') {
                    entity2 = popupdata[properties['nuts_id']].y;
                }
                content += '<div>' + this.legendLabel(this.inputDisplayObject.tableFields[0].tableDescr) + ':' + entity1 + '</div>';
                content += '<div>' + this.legendLabel(this.inputDisplayObject.tableFields[1].tableDescr) + ':' + entity2 + '</div>';
                this.regionsLayer.setFeatureStyle(properties['nuts_id'], {
                    default: {
                        weight: 3,
                        color: 'rgba(185,178,178,0.8)',
                        fillOpacity: 0
                    }
                });
                this.childGraph.highlightPoint([{x: entity1, y: entity2}]);
                // You can place the popup at the event latlng or on the layer.
                this.popup = L.popup()
                    .setContent(content)
                    .setLatLng(event.latlng)
                    .openOn(this.map);
            } else {
                // L.popup().close();
            }

        }));

        this.regionsLayer.on('mouseout', (event) => {
            this.map.closePopup(this.popup);
            this.regionsLayer.resetFeatureStyle(this.selectedArea);
        });
    }

    addMouseClick(popupdata): any {
        this.regionsLayer.on('click', (event) => {

            const properties = event.layer.properties;
            if (properties) {
                console.log('clicked:' + properties['nuts_id']);
                let entity1, entity2 = 'no data';
                if (popupdata[properties['nuts_id']] != 'null') {
                    entity1 = popupdata[properties['nuts_id']].x;
                }

                if (popupdata[properties['nuts_id']] != 'null') {
                    entity2 = popupdata[properties['nuts_id']].y;
                }
                this.selectedArea = properties['nuts_id'];

            }
            //L.DomEvent.stop(event);

        });
    }


    hideLegend() {
        if (this.mapLegendDiv !== undefined) {
            this.mapLegendDiv!.style.display = 'none';
        }


    } // END FUNCTION hideLegend

    initLegend() {
        this.mapLegendDiv.style.display = 'block';

        this.mapLegendDiv.innerHTML = '';
    } // END FUNCTION initLegend

    hideMapGraph() {
        this.graphOpen = false;
        document.getElementById('map_graph_div_graph_container').style.width = '0px';
        document.getElementById('map_graph_div_toggle_button').className = 'graphToggleContainerButtonLeft';
        this.mapGraphContainer.style.display = 'none';
    } // END FUNCTION hideMapGraph

    showMapGraph() {
        this.graphOpen = true;
        document.getElementById('map_graph_div_graph_container').style.width = '420px';
        document.getElementById('map_graph_div_toggle_button').className = 'graphToggleContainerButtonRight';
        this.mapGraphContainer.style.display = 'block';
    } // END FUNCTION showMapGraph

    hideMapInfo() {
        this.infoOpen = false;
        document.getElementById('map_info_div_info_container').style.width = '0px';
        document.getElementById('map_info_div_toggle_button').className = 'panelToggleContainerButtonLeft';
        this.mapInfoContainer.style.display = 'none';
    } // END FUNCTION hideMapInfo

    showMapInfo() {
        this.infoOpen = false;
        document.getElementById('map_graph_div_graph_container').style.width = '420px';
        document.getElementById('map_graph_div_toggle_button').className = 'panelToggleContainerButtonRight';
        this.mapInfoContainer.style.display = 'block';
    } // END FUNCTION showMapInfo

    setLegend(info): any {


        const legendType = info.type;

        // console.log('setLegend()', legendType);


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
        let svgHeight = 210;

        let containerSvg = document.createElementNS(xmlns, 'svg');
        this.mapLegendDiv.appendChild(containerSvg);
        containerSvg.setAttributeNS(null, 'class', 'legendSvgGraph');
        containerSvg.setAttributeNS(null, 'width', svgWidth.toString());
        containerSvg.setAttributeNS(null, 'height', svgHeight.toString());
        containerSvg.setAttributeNS(null, 'viewBox', '0 0 ' + svgWidth + ' ' + svgHeight);

        /*
        let bg = document.createElementNS(xmlns, 'rect');
        containerSvg.appendChild(bg);
        bg.setAttributeNS(null, 'fill', '#ffffff');
        bg.setAttributeNS(null, 'opacity', '0.5');
        bg.setAttributeNS(null, 'width', svgWidth.toString());
        bg.setAttributeNS(null, 'height', svgHeight.toString());
        // bg.addEventListener('mouseover', legendBlockMouseOut);
        */


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

                blockPath.addEventListener('click', this.legendBlockMouseOver);
                blockPath.addEventListener('mouseover', this.legendBlockMouseOver);
                blockPath.addEventListener('mouseout', this.legendBlockMouseOut);


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
        textPredictor.innerHTML = this.legendLabel(info.xlabel) + ' &#11166;';

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


        let textExplain0 = document.createElementNS(xmlns, 'text');
        containerSvg.appendChild(textExplain0);
        textExplain0.id = 'legendTextExplain0';
        textExplain0.setAttributeNS(null, 'x', '30'); //Math.floor(1 * svgWidth / 2).toString());
        textExplain0.setAttributeNS(null, 'y', '14');
        textExplain0.setAttributeNS(null, 'fill', '#000000');
        //textExplain0.setAttributeNS(null, 'text-anchor', 'middle');
        textExplain0.setAttributeNS(null, 'font-weight', 'bold');
        //textExplain0.setAttributeNS(null, 'font-style', 'italic');
        textExplain0.setAttributeNS(null, 'font-size', '12px');
        textExplain0.setAttributeNS(null, 'height', '4em');
        textExplain0.innerHTML = 'Select a colored block to see ';

        let textExplain1 = document.createElementNS(xmlns, 'text');
        containerSvg.appendChild(textExplain1);
        textExplain1.id = 'legendTextExplain1';
        textExplain1.setAttributeNS(null, 'x', '30'); // Math.floor(1 * svgWidth / 2).toString());
        textExplain1.setAttributeNS(null, 'y', '28');
        textExplain1.setAttributeNS(null, 'fill', '#000000');
        //textExplain1.setAttributeNS(null, 'text-anchor', 'middle');
        textExplain1.setAttributeNS(null, 'font-weight', 'bold');
        //textExplain1.setAttributeNS(null, 'font-style', 'italic');
        textExplain1.setAttributeNS(null, 'font-size', '12px');
        textExplain1.setAttributeNS(null, 'height', '4em');
        textExplain1.innerHTML = 'its meaning';


    } // END FUNCTION biVariateLegend

    private uniVariateLegend(info: any) {

        let legendValueDescrLine = document.createElement('div');
        this.mapLegendDiv.appendChild(legendValueDescrLine);
        legendValueDescrLine.innerHTML = this.legendLabel(this.inputDisplayObject.tableFields[this.inputDisplayObject.displayTableId].tableDescr) + ':';
        legendValueDescrLine.style.fontWeight = 'bold';
        legendValueDescrLine.style.marginBottom = '0.5em';


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
    } // END FUNCTION uniVariateLegend


    legendLabel(text: string): string {
        let label = '';
        let textparts = text.split(' ');
        if (textparts.length > 1) {
            label = textparts[0] + ' ' + textparts[1].replace('by', '');
        }
        return label;
    }


    legendBlockMouseOver(e) {
        //console.log('legendBlockMouseOver(), event:', e.target.id);
        console.log('legendBlockMouseOver(), event:', e.type);


        if (e.type === 'click') {
            // reset other blocks ...
            console.log('reset other blocks', e.target.id);
            for (let x of ['1', '2', '3']) {
                for (let y of ['1', '2', '3']) {
                    document.getElementById('legendBlock_' + x + '_' + y).setAttributeNS(null, 'stroke-opacity', '0');
                }
            }
        }


        document.getElementById(e.target.id).setAttributeNS(null, 'stroke-opacity', '1');

        //console.log('TEST:', document.getElementById(e.target.id).getAttributeNS(null, 'd'));
        // document.getElementById('legendBlockIndicator').setAttributeNS(null, 'd', document.getElementById(e.target.id).getAttributeNS(null, 'd') );

        let titleParts = document.getElementById(e.target.id).getAttributeNS(null, 'title').split('|');

        document.getElementById('legendTextExplain0').innerHTML = titleParts[0].trim();
        document.getElementById('legendTextExplain1').innerHTML = titleParts[1].trim();

    } // END FUNCTION legendBlockMouseOver

    legendBlockMouseOut(e) {
        //console.log('legendBlockMouseOut(), event:', e.target.id);
        document.getElementById(e.target.id).setAttributeNS(null, 'stroke-opacity', '0');

        // document.getElementById('legendBlockIndicator').setAttributeNS(null, 'd', 'M -100 -100 L -125 -125 L -100 -150 L -75 -125 z' );

        //document.getElementById('legendTextExplain0').innerHTML = 'Select a colored block to see ';
        //document.getElementById('legendTextExplain1').innerHTML = 'its meaning';
        document.getElementById('legendTextExplain0').innerHTML = '';
        document.getElementById('legendTextExplain1').innerHTML = '';

    } // END FUNCTION legendBlockMouseOut



    // highlight the region that is hovered by the mouse in the graph, for 3 seconds
    // better would be to highlight on mouseover en unhighlight on mouseout
    newCode($event: any) {
        if (this.oldhighligth !== '') {
            this.regionsLayer.resetFeatureStyle(this.oldhighligth);
        }
        //console.log('code', $event, this.regionsColor[$event]);
        this.oldhighligth = $event;
        this.regionsLayer.setFeatureStyle($event, {
            default: {
                weight: 3,
                color: 'rgba(255,192,0,1)',
                fillColor: this.regionsColor[$event],
                fill: true,
                fillOpacity: 1,
            }
        });

        setTimeout(() => this.regionsLayer.resetFeatureStyle($event), 5000);


    }


    public openSnack(snackText, duration = 6, actionText = null): any {
        // const snackBarRef = this.snackBar.open('Dit is nog een prototype!', 'ok', {duration: 6000});
        const snackBarRef = this.snackBar.open(snackText, actionText, {
            duration: (duration * 1000),
            panelClass: ['snackBarPageWithBottomTabsClass']
            //, verticalPosition: 'top'
        });

        return snackBarRef;
    } // END FUNCTION openSnack



} // END CLASS ResultMapComponent


