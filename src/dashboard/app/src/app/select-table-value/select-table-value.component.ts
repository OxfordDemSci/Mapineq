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


  tableSelectFormControl = new FormControl('');
  tableSelectOptions: any[];
  tableSelectFilteredOptions: Observable<any[]>;

  tableId: number;
  tableSelection: any;

  private map;
  layerMapOSM: any;

  // tables: any;

  constructor(private featureService: FeatureService) {

    this.tableSelectOptions = []; // [{f_resource: 'TST_A', f_description: 'Test table A'}];
    // this.tables = [];



  } // END CONSTRUCTOR


  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {
      // console.log('!!!!! !!!!! !!!!! !!!!! change in', propName, changes[propName].currentValue);
      const change = changes[propName];
      const valueCurrent  = change.currentValue;
      // const valuePrevious = change.previousValue;
      if (propName === 'inputTableSelection' && valueCurrent) {
        // console.log('ngOnChanges(), "inputTableSelection":', valueCurrent);
      }
    }
  } // END FUNCTION ngOnChanges

  ngOnInit(): void {
    // console.log('ngOnInit() ... ');

    /*
    this.featureService.getNutsAreas(2).subscribe((data) => {

    });
    */


    this.tableId = this.inputTableId;
    this.tableSelection = this.inputTableSelection;

    this.setTableSources();

  } // END FUNCTION ngOnInit

  ngAfterViewInit() {
    // console.log('ngAfterViewInit() ...', this.tableId, this.tableSelection);

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



  setTableSources() {
    console.log('vlak voor getSources, tableId:', this.tableId);

    if (this.tableId === 0) {
      this.featureService.getAllSources().subscribe((data) => {
        // this.tables = data;
        this.tableSelectOptions = data;

        this.tableSelectFilteredOptions = this.tableSelectFormControl.valueChanges.pipe(
            startWith(''),
            map(value => this.filterTableSelectOptions(value || '')),
        );
      });
    } else if (this.tableId === 1) {
      // getSourcesByYearAndNutsLevel year nutsleven
      console.log('getSourcesByYearAndNutsLevel(), try get values:');
      this.featureService.getSourcesByYearAndNutsLevel(1, 0).subscribe((data) => {
        // this.tables = data;
        this.tableSelectOptions = data;

        this.tableSelectFilteredOptions = this.tableSelectFormControl.valueChanges.pipe(
            startWith(''),
            map(value => this.filterTableSelectOptions(value || '')),
        );
      });
    }

  } // END FUNCTION setTableSources

  /*
  f_description
  f_resource
  */

  private filterTableSelectOptions(value: any): any[] {
    // console.log('filterTableSelectOptions(), value:', value, (typeof value));


    let filterValue = value;
    if (typeof value === 'string') {
      filterValue = value.toLowerCase();
    } else {
      filterValue = value.f_resource.toLowerCase();
    }

    // return this.options.filter(option => option.f_description.toLowerCase().includes(filterValue));
    return this.tableSelectOptions.filter( (option) => {
      // console.log('option:', filterValue, option.f_resource, option.f_description, option.f_description.toLowerCase().includes(filterValue));
      return (option.f_resource.toLowerCase().includes(filterValue)  ||  option.f_description.toLowerCase().includes(filterValue)); //   ||  value.trim() === ''
    });
  } // END FUNCTION filterTableSelectOptions


  displayTableSelectOption(option) {
    // console.log('displayTableSelectOption(), option:', option.id, option.properties.name);
    if (typeof option.f_description !== 'undefined'  &&  typeof option.f_resource !== 'undefined') {
      // return '' +  option.f_resource + ': ' +  option.f_description + ''; // option.f_description;
      return '' +  option.f_resource + '';
    } else {
      return '';
    }
  } // END FUNCTION displayTableSelectOption


  tableSelectOption(selectedOption): void {
    //console.log('tableSelectOption() ...', selectedOption, Object(this.myControl.value));
    //console.log('this.myControl.value :', this.myControl.value);

    this.tableSelection.tableName = selectedOption.f_resource;
    this.tableSelection.tableDescr = selectedOption.f_description;


    this.featureService.getInfoByReSource(this.tableSelection.tableName).subscribe( data => {
      console.log('getInfoByReSource()', this.tableSelection.tableName, data);
    });

    this.featureService.getColumnValuesBySource(this.tableSelection.tableName, 2012, 0).subscribe( data => {
      console.log('getColumnValuesBySource()', this.tableSelection.tableName, data);
    });

    //this.responseVal = Object(this.myControl.value).id;
    //this.okClick();
  } // END FUNCTION tableSelectOption

  tableSelectClearSelectedOption(autoComplete) {
    console.log('tableSelectClearSelectedOption() ...');

    this.tableSelection.tableName = '';
    this.tableSelection.tableDescr = '';

    // console.log('CHECK: ', autoComplete.options);
    autoComplete.options.forEach( option => {
      option.deselect();
    });

    this.tableSelectFormControl.reset('');

  } // END FUNCTION tableSelectClearSelectedOption





  getTables() {

  } // END FUNCTION getTables

  getTableOptions() {

  } // END FUNCTION getTableOptions









} // END CLASS SelectTableValueComponent
