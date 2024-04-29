import {AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges} from '@angular/core';
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import OSM from 'ol/source/OSM';
import {transform} from "ol/proj";

import { RegionsLayer } from '../layers/regions-layer';

import {MatFormFieldModule} from '@angular/material/form-field';
import {MatSelectModule} from '@angular/material/select';
import {FeatureService} from "../services/feature.service";
import { Overlay} from "ol";
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import {DataSource} from "../usercontrols/usercontrols.component";
import {GraphComponent} from "../graph/graph.component";


export interface Area {
  nuts_id: string;
  name: string;
}


@Component({
  selector: 'app-map',
  templateUrl: './map.component.html',
  standalone: true,
  imports: [MatSelectModule, MatFormFieldModule, CommonModule, MatIconModule, GraphComponent],
  styleUrls: ['./map.component.css']
})
export class MapComponent implements OnInit, AfterViewInit, OnChanges {

  map: Map | undefined;

  nutsLayer: any;
  birthsLayer: any;

  @Input() selectedYear = 2015;

  @Input() selectedTable?: DataSource;

  area: string = '';

  newarea?: Area;

  info = document.getElementById('info');
  currentFeature: any;
  areas: Area[] = [];

  legenditems: any[] = [];

  constructor(private featureService: FeatureService) {
  }

  ngOnInit(): void {
    // nr_births
    // for (let i = 1991; i < 2022; i++) {
    //   this.years.push(i);
    //   //this.years.push(1992);
    // }
    //unemployment

    this.initLayers();
    this.changeLegend();
  } // END ngOnInit

  ngAfterViewInit(): void {



    this.activateYear(this.selectedYear.toString());
    this.map = new Map({
      view: new View({
        center: transform([6.53601, 48.23808], 'EPSG:4326', 'EPSG:3857'),
        zoom: 5,
      }),
      layers: this.getLayers(),
      target: 'ol-map'
    });
    this.mouseclick();
    this.mouseOver();
    //this.addGraph();
  } // END ngAfterViewInit


  changeLegend() {
    this.legenditems = [];
    // @ts-ignore
    let legendstep = this.selectedTable?.maxvalue/7
    for (let i =0; i<7; i++) {
      let label = `${Math.round(legendstep*i)}`;
      if (i<6) {
        label += `-${Math.round(legendstep*(i+1))}`;
      }
      let color = this.birthsLayer.getColor(this.selectedTable?.maxvalue, legendstep*i);
      let legenditem = { 'label' : label, 'color' : color  }
      this.legenditems.push(legenditem);
    }

  }



  initLayers(): void {
    //this.nutsLayer = new NutsLayer("pgtileserv.percurban");
    // @ts-ignore
    this.birthsLayer = new RegionsLayer("pgtileserv.unemployment", this.selectedTable.maxvalue);
  }

  mouseclick(): void {
    this.map?.on('click', event => {
      const feature = this.map?.forEachFeatureAtPixel(event.pixel, (feature) => feature);
      if (feature) {
        console.log('NUTS_ID', feature.getProperties()['nuts_id']);
        this.area = feature.getProperties()['nuts_name'] + ' (' + feature.getProperties()['nuts_id'] + ')';
        let area = { 'nuts_id' : feature.getProperties()['nuts_id'], 'name' : feature.getProperties()['nuts_name']};
        this.areas.push(area);
        //console.log('areas', this.areas);
        this.newarea= area;
        //this.updateGraph();
      }
    })
  }

  mouseOver(): void {
    const tooltipContainer = document.getElementById('tooltip')!;
    const tooltipContent = document.getElementById('tooltip-content')!;

    const tooltip = new Overlay({
      element: tooltipContainer,
      autoPan: {
        animation: {
          duration: 250,
        },
      },
    });
    this.map?.addOverlay(tooltip);
    let featureId = '';
    this.map?.on('pointermove', (event) => {
      const feature = this.map?.forEachFeatureAtPixel(event.pixel, (feature) => {
        if (featureId === feature.get('nuts_id')) {
          return feature;
        };
        featureId = feature.get('nuts_id');
        // @ts-ignore
        let coordinates = this.map?.getCoordinateFromPixel(event.pixel);
        // @ts-ignore
        tooltipContent.innerHTML = '<p>' + feature.get('nuts_name') + ': ' + feature.get('entity') + '</p>';
        //tooltipContent.innerHTML += '<p>' + feature.get('nuts_name') + ': ' + feature.get('entity1') + '</p>';
        tooltip.setPosition(coordinates);
        return feature;
      });
      if (!feature && (featureId != '')) {
        featureId = '';
        tooltip.setPosition(undefined);
      }
    });
  }


  activateYear(year: string) {
    this.birthsLayer.setYear(year);
  }

  private getLayers(): any[] {
    return [
      new TileLayer({
        source: new OSM(),
      }),
      this.birthsLayer,
    ]
  }






  selectTable() {

    // @ts-ignore
    this.birthsLayer.changeTable('pgtileserv.' + this.selectedTable?.table, this.selectedYear.toString(), this.selectedTable.maxvalue);
    this.birthsLayer.changeStyle();
    this.changeLegend();
  }

  selectYear(): void {
    console.log('year', this.selectedYear);
    this.activateYear(this.selectedYear.toString());
  }


  ngOnChanges(changes: SimpleChanges) {
    // changes.prop contains the old and the new value...
    if (this.birthsLayer === undefined) {
      return;
    }
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
    }
  }
}
