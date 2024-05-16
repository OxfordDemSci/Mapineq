import { AfterViewInit, Component, EventEmitter, Input, OnChanges, OnInit, Output, SimpleChanges } from '@angular/core';

import * as L from 'leaflet';
import {FeatureService} from "../services/feature.service";
import {FormControl} from "@angular/forms";
import {Observable, startWith, map} from "rxjs";
import {DisplayTableValueObject} from "../lib/display-table-value-object";


@Component({
  selector: 'app-select-table-value',
  templateUrl: './select-table-value.component.html',
  styleUrl: './select-table-value.component.css'
})
export class SelectTableValueComponent implements OnInit, AfterViewInit, OnChanges {

  @Input() inputTableId!: any;
  @Input() inputTableSelection!: any;
  @Input() inputOtherTableSelection: any;

  @Output() updateTableValueFromSelect = new EventEmitter();


  tableSelectFormControl = new FormControl('');
  tableSelectOptions: any[];
  tableSelectFilteredOptions: Observable<any[]>;

  tableId: number;
  tableSelection: DisplayTableValueObject;
  otherTableSelection: DisplayTableValueObject;

  availableYearsAndRegionLevels: any[];
  availableYears: string[];
  availableRegionLevels: string[];


  availableColumnValues: any[];
  // selectedColumnValues: any;



  private map;
  layerMapOSM: any;

  // tables: any;

  constructor(private featureService: FeatureService) {

    this.tableSelectOptions = []; // [{f_resource: 'TST_A', f_description: 'Test table A'}];
    // this.tables = [];

    this.availableYearsAndRegionLevels = [];
    this.availableYears = [];
    this.availableRegionLevels = ['3', '2', '1', '0'];

    this.availableColumnValues = [];
    // this.selectedColumnValues = {};

  } // END CONSTRUCTOR


  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {
      // console.log('!!!!! !!!!! !!!!! !!!!! change in', propName, changes[propName].currentValue);
      const change = changes[propName];
      const valueCurrent  = change.currentValue;
      // const valuePrevious = change.previousValue;

      if (propName === 'inputTableSelection' && valueCurrent) {
        // console.log('ngOnChanges(), "inputTableSelection":', valueCurrent);
        // this.tableSelection = new DisplayTableValueObject(this.inputTableSelection);
        this.tableSelection = this.inputTableSelection;
      }

      if (propName === 'inputOtherTableSelection' && valueCurrent) {
        // console.log('ngOnChanges(), "inputOtherTableSelection":', valueCurrent);
        // this.otherTableSelection = new DisplayTableValueObject(this.inputOtherTableSelection);
        this.otherTableSelection = this.inputOtherTableSelection;
        this.setTableSources();
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
    this.otherTableSelection = this.inputOtherTableSelection;

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
    // console.log('vlak voor getSources, tableId:', this.tableId);

    if (this.tableId === 0) {
      // this.featureService.getAllSources().subscribe((data) => {
      this.featureService.getResourceByNutsLevel(this.tableSelection.tableRegionLevel).subscribe((data) => {
        // this.tables = data;
        this.tableSelectOptions = data;

        this.tableSelectFilteredOptions = this.tableSelectFormControl.valueChanges.pipe(
            startWith(''),
            map(value => this.filterTableSelectOptions(value || '')),
        );
      });
    } else if (this.tableId === 1) {
      // getSourcesByYearAndNutsLevel year & nuts level
      // console.log('getSourcesByYearAndNutsLevel(), try get values:', this.otherTableSelection.tableYear, this.otherTableSelection.tableRegionLevel);
      this.featureService.getSourcesByYearAndNutsLevel(this.otherTableSelection.tableYear, this.otherTableSelection.tableRegionLevel).subscribe((data) => {
        // this.tables = data;
        this.tableSelectOptions = data;

        // console.log('this.tableSelectOptions: ', this.tableSelectOptions);
        let selectedTableStillAvailable = false;
        this.tableSelectOptions.forEach( option => {
          if (option.f_resource === this.tableSelection.tableName) {
            selectedTableStillAvailable = true;
          }
        })
        if (!selectedTableStillAvailable) {
          this.tableSelection.tableName = '';
          this.tableSelection.tableDescr = '';
          this.tableSelection.tableColumnValues = {};
          this.availableColumnValues = [];
        }


        this.tableSelectFilteredOptions = this.tableSelectFormControl.valueChanges.pipe(
            startWith(''),
            map(value => this.filterTableSelectOptions(value || '')),
        );

        //this.tableSelection.tableYear = this.otherTableSelection.tableYear;
        //this.tableSelection.tableRegionLevel = this.otherTableSelection.tableRegionLevel;




      });
    }

    this.emitChangeTableValue();

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

    // this.emitChangeTableValue();

    if (this.tableSelection.tableId !== 1) {
      this.tableSelection.tableYear = '';
      // this.tableSelection.tableRegionLevel = '';
    } else {
      this.tableSelection.tableYear = this.otherTableSelection.tableYear;
      this.tableSelection.tableRegionLevel = this.otherTableSelection.tableRegionLevel;
    }

    this.availableYearsAndRegionLevels = [];
    this.availableYears = [];
    // this.availableRegionLevels = [];

    this.featureService.getInfoByReSource(this.tableSelection.tableName).subscribe( data => {
      this.availableYearsAndRegionLevels = data;
      this.setAvailableYears();
      // if (this.tableSelection.tableId === 1) {
      //   this.setAvailableRegionLevelsForYear();
      // }
    });

    /*
    this.featureService.getColumnValuesBySource(this.tableSelection.tableName, 2012, 0).subscribe( data => {
      console.log('getColumnValuesBySource()', this.tableSelection.tableName, data);
    });
    */

    //this.responseVal = Object(this.myControl.value).id;
    //this.okClick();

    if (this.tableSelection.tableId === 1) {
      this.checkTableValueSelectionComplete();
      this.getFieldsForTableForYearAndRegionLevel();
    }

    this.emitChangeTableValue();

  } // END FUNCTION tableSelectOption





  tableSelectClearSelectedOption(autoComplete) {
    console.log('tableSelectClearSelectedOption() ...');

    this.tableSelection.tableName = '';
    this.tableSelection.tableDescr = '';
    this.tableSelection.tableYear = '-1';
    // this.tableSelection.tableRegionLevel = '-1';
    this.tableSelection.tableColumnValues = {};

    this.availableYearsAndRegionLevels = [];
    this.availableYears = [];
    // this.availableRegionLevels = [];

    this.availableColumnValues = [];
    // this.selectedColumnValues = {};


    // console.log('CHECK: ', autoComplete.options);
    autoComplete.options.forEach( option => {
      option.deselect();
    });

    this.tableSelectFormControl.reset('');

    this.checkTableValueSelectionComplete();


    this.emitChangeTableValue();
  } // END FUNCTION tableSelectClearSelectedOption


  tableSelectClearChosenColumnValues() {
    this.getFieldsForTableForYearAndRegionLevel();
  } // END FUNCTION tableSelectClearChosenColumnValues




    emitChangeTableValue() {
    // console.log('emitChangeTableValue() .. id:', this.tableSelection.tableId);
    // console.log('VOOR ' + this.tableSelection.tableId.toString(), this.tableSelection);
    // this.tableSelection = new DisplayTableValueObject(this.tableSelection);
    // console.log('ERNA ' + this.tableSelection.tableId.toString(), this.tableSelection);
    this.updateTableValueFromSelect.emit(this.tableSelection);
    // this.updateTableValueFromSelect.emit(new DisplayTableValueObject(this.tableSelection));
  }



  setAvailableYears() {
    this.availableYears = [];

    this.availableYearsAndRegionLevels.forEach( row => {
      // only add years with correct (chosen) level
      if (row.f_level === this.tableSelection.tableRegionLevel  &&  !this.availableYears.includes(row.f_year)) {
        this.availableYears.push(row.f_year);
      }
      // console.log('- ', row.f_year, row.f_level);
    })

    this.availableYears.sort();
    this.availableYears.reverse();

    // console.log('availableYears: ', this.availableYears);
  } // END FUNCTION setAvailableYears

  setAvailableRegionLevelsForYear() {
    // console.log('setAvailableRegionLevelsForYear(), year:', this.tableSelection.tableYear);

    this.availableRegionLevels = [];

    this.availableYearsAndRegionLevels.forEach( row => {
      if (row.f_year === this.tableSelection.tableYear  &&  !this.availableRegionLevels.includes(row.f_level)) {
        this.availableRegionLevels.push(row.f_level);
      }
      // console.log('- ', row.f_year, row.f_level);
    })

    this.availableRegionLevels.sort();
    this.availableRegionLevels.reverse();

    if (this.tableSelection.tableId === 1) {
      this.getFieldsForTableForYearAndRegionLevel();
    }

    // console.log('availableRegionLevels: ', this.availableRegionLevels);
  } // END FUNCTION setAvailableRegionLevelsForYear


  getFieldsForTableForYearAndRegionLevel() {
    // console.log(' >>> >>>  getFieldsForTableForYearAndRegionLevel(), tableId', this.tableSelection.tableId);
    //console.log('getFieldsForTableForYearAndRegionLevel(), year, regionLevel', this.tableSelection.tableYear, this.tableSelection.tableRegionLevel);
    this.availableColumnValues = [];
    // this.selectedColumnValues = {};
    this.tableSelection.tableColumnValues = {};

    this.emitChangeTableValue();

    this.featureService.getColumnValuesBySource(this.tableSelection.tableName, this.tableSelection.tableYear, this.tableSelection.tableRegionLevel).subscribe( data => {
      // console.log('getColumnValuesBySource()', this.tableSelection.tableName, this.tableSelection.tableYear, this.tableSelection.tableRegionLevel, data);
      this.availableColumnValues = [];
      // this.selectedColumnValues = new Array(data.length).fill('');
      data.forEach( row => {
        let jsonToPush = row;
        jsonToPush.field_values = JSON.parse(jsonToPush.field_values);

        // console.log('jsonToPush:' ,jsonToPush);
        // this.selectedColumnValues[jsonToPush.field] = '';

        if (jsonToPush.field_values.length === 1) {
          this.tableSelection.tableColumnValues[jsonToPush.field] = jsonToPush.field_values[0].value;
        } else {
          this.tableSelection.tableColumnValues[jsonToPush.field] = '';
        }

        this.availableColumnValues.push(jsonToPush);

      });


      this.checkTableValueSelectionComplete();

    });



  } // END FUNCTION getFieldsForTableForYearAndRegionLevel


  getFilteredFieldsForTableForYearAndRegionLevel() {
    // console.log(' >>> >>>  getFilteredFieldsForTableForYearAndRegionLevel(), tableId', this.tableSelection.tableId);
    //console.log('getFilteredFieldsForTableForYearAndRegionLevel(), year, regionLevel', this.tableSelection.tableYear, this.tableSelection.tableRegionLevel);

    // this.availableColumnValues = [];
    // this.tableSelection.tableColumnValues = {};
    // this.emitChangeTableValue();

    let sourceSelectionJson = {};
    sourceSelectionJson['year'] = this.tableSelection.tableYear;
    sourceSelectionJson['level'] = this.tableSelection.tableRegionLevel;

    let selectedJson = []
    for (const fieldName in this.tableSelection.tableColumnValues) {
      // console.log('- ', fieldName, this.tableSelection.tableColumnValues[fieldName]);
      if (this.tableSelection.tableColumnValues[fieldName].trim() !== '') {
        selectedJson.push({field: fieldName, value: this.tableSelection.tableColumnValues[fieldName]});
      }
    }
    sourceSelectionJson['selected'] = selectedJson;

    this.featureService.getColumnValuesBySourceJson(this.tableSelection.tableName, JSON.stringify(sourceSelectionJson)).subscribe( data => {
      console.log('getColumnValuesBySourceJson()', data);

      this.availableColumnValues = [];

      data.forEach( row => {
        let jsonToPush = row;
        jsonToPush.field_values = JSON.parse(jsonToPush.field_values);

        if (jsonToPush.field_values.length === 1) {
          this.tableSelection.tableColumnValues[jsonToPush.field] = jsonToPush.field_values[0].value;
        }

        this.availableColumnValues.push(jsonToPush);
      });


      this.checkTableValueSelectionComplete();

      /*
      this.availableColumnValues = [];
      // this.selectedColumnValues = new Array(data.length).fill('');
      data.forEach( row => {
        let jsonToPush = row;
        jsonToPush.field_values = JSON.parse(jsonToPush.field_values);

        // console.log('jsonToPush:' ,jsonToPush);
        // this.selectedColumnValues[jsonToPush.field] = '';

        if (jsonToPush.field_values.length === 1) {
          this.tableSelection.tableColumnValues[jsonToPush.field] = jsonToPush.field_values[0].value;
        } else {
          this.tableSelection.tableColumnValues[jsonToPush.field] = '';
        }

        this.availableColumnValues.push(jsonToPush);

      });
      */
    });

  } // END FUNCTION getFilteredFieldsForTableForYearAndRegionLevel

  tableSelectClearChosenColumnValue(columnValueName: string) {
    this.tableSelection.tableColumnValues[columnValueName] = '';
    this.getFilteredFieldsForTableForYearAndRegionLevel();
  } // END FUNCTION tableSelectClearChosenColumnValue


  changedColumnValue() {
    this.getFilteredFieldsForTableForYearAndRegionLevel();

    this.checkTableValueSelectionComplete();
  } // END FUNCTION changedColumnValue



  checkTableValueSelectionComplete() {
    // console.log('checkTableValueSelectionComplete() ...', this.tableSelection.tableId);

    this.tableSelection.checkSelectionComplete();
    this.emitChangeTableValue();
  } // END FUNCTION checkTableValueSelectionComplete



  checkByClick() {
    console.log('C H E C K  -  checkByClick()', this.otherTableSelection, this.inputOtherTableSelection);

  } // END FUNCTION checkByClick


  // dit hieronder kan waarschijnlijk weer weg als Object.values() niet in html wordt gebruikt ...
  /*
  protected readonly Object = Object;
  */

} // END CLASS SelectTableValueComponent

