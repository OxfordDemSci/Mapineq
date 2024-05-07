import { AfterViewInit, Component, EventEmitter, Input, OnChanges, OnInit, Output, SimpleChanges } from '@angular/core';

import * as L from 'leaflet';
import {FeatureService} from "../services/feature.service";
import {FormControl} from "@angular/forms";
import {Observable, startWith, map} from "rxjs";


@Component({
  selector: 'app-select-table-value',
  templateUrl: './select-table-value.component.html',
  styleUrl: './select-table-value.component.css'
})
export class SelectTableValueComponent implements OnInit, AfterViewInit, OnChanges {

  @Input() inputTableId!: any;
  @Input() inputTableSelection!: any;

  @Output() updateTableSelectionFromCell = new EventEmitter();


  myControl = new FormControl('');
  options: any[];
  filteredOptions: Observable<any[]>;

  tableId: number;
  tableSelection: any;

  private map;
  layerMapOSM: any;

  tables: any;

  constructor(private featureService: FeatureService) {

    this.options = []; // [{f_resource: 'TST_A', f_description: 'Test table A'}];
    this.tables = [];

    this.featureService.getAllSources().subscribe( (data) => {
      this.tables = data;
      this.options = data;

      this.filteredOptions = this.myControl.valueChanges.pipe(
          startWith(''),
          map(value => this._filter(value || '')),
      );

    });


  } // END CONSTRUCTOR

  /*
  f_description
  f_resource
  */

  private _filter(value: any): any[] {
    // console.log('_filter(), value:', value, (typeof value));


    let filterValue = value;
    if (typeof value === 'string') {
      filterValue = value.toLowerCase();
    } else {
      filterValue = value.f_resource.toLowerCase();
    }

    // return this.options.filter(option => option.f_description.toLowerCase().includes(filterValue));
    return this.options.filter( (option) => {
      // console.log('option:', filterValue, option.f_resource, option.f_description, option.f_description.toLowerCase().includes(filterValue));
      return (option.f_resource.toLowerCase().includes(filterValue)  ||  option.f_description.toLowerCase().includes(filterValue)); //   ||  value.trim() === ''
    });
  } // END FUNCTION _filter


  displayOption(option) {
    // console.log('displayOption(), option:', option.id, option.properties.name);
    if (typeof option.f_description !== 'undefined'  &&  typeof option.f_resource !== 'undefined') {
      // return '' +  option.f_resource + ': ' +  option.f_description + ''; // option.f_description;
      return '' +  option.f_resource + '';
    } else {
      return '';
    }
  } // END FUNCTION displayOption


  selectOption(selectedOption): void {
    //console.log('selectOption() ...', selectedOption, Object(this.myControl.value));
    //console.log('this.myControl.value :', this.myControl.value);

    this.tableSelection.tableName = selectedOption.f_resource;
    this.tableSelection.tableDescr = selectedOption.f_description;


    //this.responseVal = Object(this.myControl.value).id;
    //this.okClick();
  } // END FUNCTION selectOption

  clearSelectedOption(autoComplete) {
    console.log('clearSelectedOption() ...');

    this.tableSelection.tableName = '';
    this.tableSelection.tableDescr = '';

    // console.log('CHECK: ', autoComplete.options);
    autoComplete.options.forEach( option => {
      option.deselect();
    });

    this.myControl.reset('');

  } // END FUNCTION clearSelectedOption


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

    /*
    this.featureService.getNutsAreas(2).subscribe((data) => {

    });
    */


    this.tableId = this.inputTableId;
    this.tableSelection = this.inputTableSelection;
  } // END FUNCTION ngOnInit

  ngAfterViewInit() {
    console.log('ngAfterViewInit() ...', this.tableId, this.tableSelection);

    // this.initTableValueMap();

  } // END FUNCTION ngAfterViewInit

  initTableValueMap() {
    let mapId = 'map_' + this.tableId.toString();
    console.log('initTableValueMap CALLED ... ', mapId);

    let test = document.getElementById(mapId);
    console.log('map element:', test);

    this.layerMapOSM = L.tileLayer(
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors',
          minZoom: 0,
          maxZoom: 21
        });

    this.map = L.map(mapId);

    this.map.addLayer(this.layerMapOSM);

    this.map.fitBounds(L.latLng(53.238, 6.536).toBounds(3000000));



  } // END FUNCTION initTableValueMap






  getTables() {

  } // END FUNCTION getTables

  getTableOptions() {

  } // END FUNCTION getTableOptions

} // END CLASS SelectTableValueComponent
