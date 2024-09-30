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

  @Input() inputUseCase: number;
  @Input() inputUseCaseData: any;

  @Input() region: string;


  @Output() updateTableValueFromSelect = new EventEmitter();

  componentInitiated: boolean;

  useCaseOtherTableLoaded: number;

  tableSelectFormControl = new FormControl('');
  tableSelectOptions: any[];
  tableSelectFilteredOptions: Observable<any[]>;
  availableTableNames: string[];

  tableId: number;
  tableSelection: DisplayTableValueObject;
  otherTableSelection: DisplayTableValueObject;

  availableYearsAndRegionLevels: any[];
  availableYears: string[];
  availableRegionLevels: string[];

  regionLevelsText: any;

  availableRegionLevelsForTable: string[];

  availableColumnValues: any[];
  availableColumnValuesWithInitiallyOneChoice: string[];
  availableColumnValuesManuallyChanged: string[];
  // selectedColumnValues: any;



  private map;
  layerMapOSM: any;

  // tables: any;

  constructor(private featureService: FeatureService) {

    this.componentInitiated = false;

    this.useCaseOtherTableLoaded = 0;

    this.inputUseCase = -1;
    this.inputUseCaseData = [];
    this.region = "";

    this.tableSelectOptions = []; // [{f_resource: 'TST_A', f_description: 'Test table A'}];
    // this.tables = [];
    this.availableTableNames = [];

    this.availableYearsAndRegionLevels = [];
    this.availableYears = [];
    //this.availableRegionLevels = ['3', '2', '1', '0'];

    this.regionLevelsText = {'0': 'countries', '1': 'large regions', '2': 'base regions', '3': 'small regions'};

    this.availableRegionLevelsForTable = [];

    this.availableColumnValues = [];
    this.availableColumnValuesWithInitiallyOneChoice = [];
    this.availableColumnValuesManuallyChanged = [];
    // this.selectedColumnValues = {};

  } // END CONSTRUCTOR


  ngOnInit(): void {
    console.log('ngOnInit() ... ');

    /*
    this.featureService.getNutsAreas(2).subscribe((data) => {

    });
    */


    this.tableId = this.inputTableId;
    this.tableSelection = this.inputTableSelection;
    this.otherTableSelection = this.inputOtherTableSelection;

    //console.log('before abc ngOnInit ...', this.tableSelection.tableId);
    this.setAvailableRegionLevels();


    // this.setTableSources(); // KAN UIT?

    this.componentInitiated = true;
  } // END FUNCTION ngOnInit

  ngAfterViewInit() {
    // console.log('ngAfterViewInit() ...', this.tableId, this.tableSelection);

    // this.initTableValueMap();

  } // END FUNCTION ngAfterViewInit


  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {
      //console.log('!!!!! !!!!! !!!!! !!!!! change in', propName, changes[propName].currentValue, changes[propName].previousValue);
      const change = changes[propName];
      const valueCurrent  = change.currentValue;
      // const valuePrevious = change.previousValue;

      /*
      if (propName === 'inputUseCaseData' && valueCurrent  &&  this.componentInitiated) {
        console.log('before abc - ngOnChanges(), "inputUseCaseData":', valueCurrent, ' inputTableId', this.inputTableId, this.componentInitiated, this.inputUseCaseData);
        this.setAvailableRegionLevels();
      }
      */

      if (propName === 'inputTableSelection' && valueCurrent) {
        // DEZE REGEL HIERONDER MISTE ...
        //console.log('before abc - ngOnChanges(), "inputTableSelection":', this.tableSelection.tableId);
        this.tableSelection = this.inputTableSelection;
        // this.checkTableValueSelectionComplete(); // deze _hier_ aanroepen zorgt dat hij blijft checken en niet (kaart) plot
      }

      if (propName === 'inputOtherTableSelection' && valueCurrent  &&  this.componentInitiated) {
      // if (propName === 'inputOtherTableSelection' && valueCurrent  &&  this.componentInitiated  &&  this.inputUseCase === -1) {
        // console.log('ngOnChanges(), "inputOtherTableSelection":', valueCurrent);
        // this.otherTableSelection = new DisplayTableValueObject(this.inputOtherTableSelection);


        //console.log('before abc - ngOnChanges(), "inputOtherTableSelection" CHECK:', this.inputTableId, this.inputUseCase, this.useCaseOtherTableLoaded, this.inputOtherTableSelection.tableName, this.tableSelection.tableName);
        if (this.inputUseCase === -1  ||  this.useCaseOtherTableLoaded < 3) {
          //console.log('before abc - ngOnChanges(), "inputOtherTableSelection", inputTableId', this.inputTableId, this.componentInitiated, this.inputOtherTableSelection.tableName, this.tableSelection.tableName, this.inputUseCaseData);
          this.otherTableSelection = this.inputOtherTableSelection;
          this.setTableSources();
          this.useCaseOtherTableLoaded++;
        }
        if (this.inputOtherTableSelection.tableName === '') {
          this.useCaseOtherTableLoaded = 0; // SJO 20240909
        }
      }

      if (propName === 'region'  &&  this.componentInitiated) {
        //console.log('********** change in', propName, changes[propName].currentValue, changes[propName].previousValue);
        this.tableId = 0;
        //console.log('before abc - ngOnChanges(), "region":', valueCurrent, ' inputTableId', this.inputTableId, this.componentInitiated, this.inputUseCaseData);
        this.setTableSources();
        // console.log('this.tableSelection.tableName=' + this.tableSelection.tableName)
      }
    }
  } // END FUNCTION ngOnChanges




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

  setAvailableRegionLevels() {

    this.featureService.getNutsLevels(this.inputUseCase).subscribe( data => {
      // console.log('A setAvailableRegionLevels(), usecase/data:', this.inputUseCase, data);
      // this.availableRegionLevels = data;
      // this.availableRegionLevels = data.map((item) => {return item.f_year;});
      this.availableRegionLevels = data.map((item) => {return item.f_level;});
      /*
      data.forEach( dataObject => {
        if (typeof dataObject.f_year !== 'undefined') {
          this.availableRegionLevels.push(dataObject.f_year);
        }
      })
      */
      // this.availableRegionLevels = ['0', '1', '2', '3'].slice().reverse();

      if (this.inputUseCase > -1  &&  this.inputUseCaseData.length > 0) {
        //console.log('B setAvailableRegionLevels(), ', this.inputTableId, this.inputUseCaseData[this.inputTableId].tableRegionLevel, this.availableRegionLevels);

        if ( this.availableRegionLevels.includes(this.inputUseCaseData[this.inputTableId].tableRegionLevel) ) {
          this.tableSelection.tableRegionLevel = this.inputUseCaseData[this.inputTableId].tableRegionLevel;

          // this.tableSelection.tableRegionLevel = '2';
          //console.log('before abc - before calling setTableSources() vanuit setAvailableRegionLevels()', this.tableSelection.tableId);
          this.setTableSources();
        }
      }
    });
  } // END FUNCTION setAvailableRegionLevels


  regionLevelChanged() {

    if (this.tableId === 0) {
      // this.tableSelection.tableRegionLevel = this.otherTableSelection.tableRegionLevel;
      // this.otherTableSelection.tableRegionLevel = this.tableSelection.tableRegionLevel;
      this.tableSelection.tableName = ''; // necessary to clear table if data unavailable for chosen level
      this.updateTableValueFromSelect.emit(this.tableSelection);

    }

    this.setTableSources();

  } // END FUNCTION regionLevelChanged


  setTableSources() {
    // console.log('vlak voor getSources, tableId:', this.tableId);

    if (this.tableId === 0) {
      // this.featureService.getAllSources().subscribe((data) => {
      this.featureService.getResourceByNutsLevel(this.tableSelection.tableRegionLevel, this.inputUseCase).subscribe((data) => {
        // this.tables = data;
        this.tableSelectOptions = data;

        this.availableTableNames = data.map( dataItem => {return dataItem.f_resource});

        this.tableSelectFilteredOptions = this.tableSelectFormControl.valueChanges.pipe(
            startWith(''),
            map(value => this.filterTableSelectOptions(value || '')),
        );
        if (this.region !== '') {
          console.log('this.region', this.region);
          if (this.availableTableNames.includes(this.tableSelection.tableName)) {
            // console.log('TABLENAME setten', this.inputTableId);
            // this.tableSelection.tableName = this.inputUseCaseData[this.inputTableId].tableName;

            let selectedTableObject = this.tableSelectOptions.filter( tableObject => {
              return tableObject.f_resource === this.tableSelection.tableName;
            })

            //console.log('before abc A - selectedTableObject: ', this.tableSelection.tableId, selectedTableObject);
            this.tableSelectOption(selectedTableObject[0]);

          }
        }


        if (this.tableSelection.lastTableName !== ''  &&  this.availableTableNames.includes(this.tableSelection.lastTableName)) {

          //  console.log("==> setTableSources(), set previous tableName", this.inputTableId, this.tableSelection.lastTableName, this.availableTableNames);
          // if (this.availableTableNames.includes(this.tableSelection.lastTableName)) {
          // console.log('TABLENAME setten', this.inputTableId);
          // this.tableSelection.tableName = this.inputUseCaseData[this.inputTableId].tableName;

          let selectedTableObject = this.tableSelectOptions.filter(tableObject => {
            return tableObject.f_resource === this.tableSelection.lastTableName;
          })

          //console.log('before abc B - selectedTableObject: ', this.tableSelection.tableId, selectedTableObject);
          this.tableSelectOption(selectedTableObject[0]);

          // }

        } else {

          if (this.inputUseCase > -1) {
            // tableSelection.tableName
            //  console.log("==> setTableSources(), set case value", this.inputTableId, this.inputUseCaseData[this.inputTableId].tableName, this.availableTableNames);
            if (this.availableTableNames.includes(this.inputUseCaseData[this.inputTableId].tableName)) {
              // console.log('TABLENAME setten', this.inputTableId);
              // this.tableSelection.tableName = this.inputUseCaseData[this.inputTableId].tableName;

              let selectedTableObject = this.tableSelectOptions.filter(tableObject => {
                return tableObject.f_resource === this.inputUseCaseData[this.inputTableId].tableName;
              })

              //console.log('before abc B - selectedTableObject: ', this.tableSelection.tableId, selectedTableObject);
              this.tableSelectOption(selectedTableObject[0]);

            }

          }

        }

      });
    } else if (this.tableId === 1) {
      // getSourcesByYearAndNutsLevel year & nuts level
      // console.log('getSourcesByYearAndNutsLevel(), try get values:', this.otherTableSelection.tableYear, this.otherTableSelection.tableRegionLevel);
      this.featureService.getSourcesByYearAndNutsLevel(this.otherTableSelection.tableYear, this.otherTableSelection.tableRegionLevel, this.inputUseCase).subscribe((data) => {
        // this.tables = data;
        this.tableSelectOptions = data;

        this.availableTableNames = data.map( dataItem => {return dataItem.f_resource});

        // console.log('this.tableSelectOptions: ', this.tableSelectOptions);
        let selectedTableStillAvailable = false;
        this.tableSelectOptions.forEach( option => {
          if (option.f_resource === this.tableSelection.tableName) {
            selectedTableStillAvailable = true;
          }
        })
        if (!selectedTableStillAvailable) {
          //console.log('before abc !selectedTableStillAvailable ...', this.tableSelection.tableId);

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


        if (this.tableSelection.lastTableName !== ''  &&  this.availableTableNames.includes(this.tableSelection.lastTableName)) {

          //  console.log("==> setTableSources(), set previous tableName", this.inputTableId, this.tableSelection.lastTableName, this.availableTableNames);
          // if (this.availableTableNames.includes(this.tableSelection.lastTableName)) {
          // console.log('TABLENAME setten', this.inputTableId);
          // this.tableSelection.tableName = this.inputUseCaseData[this.inputTableId].tableName;

          let selectedTableObject = this.tableSelectOptions.filter(tableObject => {
            return tableObject.f_resource === this.tableSelection.lastTableName;
          })

          //console.log('before abc B - selectedTableObject: ', this.tableSelection.tableId, selectedTableObject);
          this.tableSelectOption(selectedTableObject[0]);

          // }

        } else {
          if (this.inputUseCase > -1) {
            // tableSelection.tableName
            //  console.log("==> setTableSources(), set case value", this.inputTableId, this.inputUseCaseData[this.inputTableId].tableName, this.availableTableNames);
            if (this.availableTableNames.includes(this.inputUseCaseData[this.inputTableId].tableName)) {
              // console.log('TABLENAME setten', this.inputTableId);
              // this.tableSelection.tableName = this.inputUseCaseData[this.inputTableId].tableName;

              let selectedTableObject = this.tableSelectOptions.filter(tableObject => {
                return tableObject.f_resource === this.inputUseCaseData[this.inputTableId].tableName;
              })

              //console.log('before abc C - selectedTableObject: ', this.tableSelection.tableId, selectedTableObject);
              this.tableSelectOption(selectedTableObject[0]);

            }

          }
        }

      });
    }



    // this.emitChangeTableValue(); // KAN DEZE ERUIT????

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

    this.tableSelection.lastTableName = this.tableSelection.tableName;

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

    console.log('before this.featureService.getInfoByReSource()', this.tableSelection.tableId, this.tableSelection.tableName);
    this.featureService.getInfoByReSource(this.tableSelection.tableName, this.inputUseCase).subscribe( data => {
      this.availableYearsAndRegionLevels = data;
      this.setAvailableYears();

      // console.log('REFRESH available region levels for selected table ... ... ... ... ... ');
      this.availableRegionLevelsForTable = [];
      data.forEach( row => {
        // only add years with correct (chosen) level
        if (!this.availableRegionLevelsForTable.includes(row.f_level)) {
          this.availableRegionLevelsForTable.push(row.f_level);
        }
      });

      this.availableRegionLevelsForTable.sort();

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
      // this.checkTableValueSelectionComplete(); // SJO 20240903 DEZE MSS OVERBODIG?
      this.getFieldsForTableForYearAndRegionLevel();
    }

    this.emitChangeTableValue();

  } // END FUNCTION tableSelectOption



  tableSelectClearSelectedOption(autoComplete) {
    //console.log('before abc tableSelectClearSelectedOption() ...', this.inputTableId);


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

    if (this.tableSelection.tableId === 0  &&  this.inputUseCase > -1) {
      //console.log('before abc  RESET ...');
      // this.useCaseOtherTableLoaded = 0; // ANDERE useCaseOtherTableLoaded zou weer op nul moeten worden gezet ...
    }

    this.emitChangeTableValue();
  } // END FUNCTION tableSelectClearSelectedOption


  tableSelectClearChosenColumnValues() {
    this.getFieldsForTableForYearAndRegionLevel();
  } // END FUNCTION tableSelectClearChosenColumnValues

  showOnlyThisTableOnMap() {
    this.tableSelection.tableShowOnlyThisTable = true;
    this.emitChangeTableValue();
  } // END FUNCTION showOnlyThisTableOnMap



  emitChangeTableValue() {
    // console.log('emitChangeTableValue() .. id:', this.tableSelection.tableId);
    // console.log('VOOR ' + this.tableSelection.tableId.toString(), this.tableSelection);
    // this.tableSelection = new DisplayTableValueObject(this.tableSelection);
    // console.log('ERNA ' + this.tableSelection.tableId.toString(), this.tableSelection);
    this.updateTableValueFromSelect.emit(this.tableSelection);
    // this.updateTableValueFromSelect.emit(new DisplayTableValueObject(this.tableSelection));
  }



  setAvailableYears() {
    // console.log('CALLED setAvailableYears() ... ', this.tableSelection.tableId, JSON.stringify(this.availableYearsAndRegionLevels));

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


    if (this.tableSelection.lastTableYear !== ''  &&  this.availableYears.includes(this.tableSelection.lastTableYear)) {
      this.tableSelection.tableYear = this.tableSelection.lastTableYear;
      this.getFieldsForTableForYearAndRegionLevel();
    } else {
      if (this.inputUseCase > -1 && this.inputTableId === 0) {
        console.log('CHECK YEAR: ', this.inputUseCaseData[this.inputTableId]);
        if (this.availableYears.includes(this.inputUseCaseData[this.inputTableId].tableYear)) {
          this.tableSelection.tableYear = this.inputUseCaseData[this.inputTableId].tableYear;
          this.getFieldsForTableForYearAndRegionLevel();
        }
      }
    }

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
    // console.trace('TRACE0', this.tableSelection.tableId);
    //console.log('getFieldsForTableForYearAndRegionLevel(), year, regionLevel', this.tableSelection.tableYear, this.tableSelection.tableRegionLevel);
    this.availableColumnValues = [];
    this.availableColumnValuesWithInitiallyOneChoice = [];
    this.availableColumnValuesManuallyChanged = [];
    // this.selectedColumnValues = {};
    this.tableSelection.tableColumnValues = {};


    this.tableSelection.lastTableYear = this.tableSelection.tableYear;



    // this.emitChangeTableValue(); // SJO 20240903 - MSS OVERBODIG ??


    let sourceSelectionJson = {};
    sourceSelectionJson['year'] = this.tableSelection.tableYear;
    sourceSelectionJson['level'] = this.tableSelection.tableRegionLevel;

    let selectedJson = []
    sourceSelectionJson['selected'] = selectedJson;

    this.featureService.getColumnValuesBySourceJson(this.tableSelection.tableName, JSON.stringify(sourceSelectionJson), this.inputUseCase).subscribe( data => {
      // this.featureService.getColumnValuesBySource(this.tableSelection.tableName, this.tableSelection.tableYear, this.tableSelection.tableRegionLevel).subscribe( data => {
      // console.log('getColumnValuesBySource()', this.tableSelection.tableName, this.tableSelection.tableYear, this.tableSelection.tableRegionLevel, data);

      this.availableColumnValues = [];
      this.availableColumnValuesWithInitiallyOneChoice = [];
      this.availableColumnValuesManuallyChanged = [];
      // this.selectedColumnValues = new Array(data.length).fill('');
      data.forEach( row => {
        let jsonToPush = row;
        jsonToPush.field_values = JSON.parse(jsonToPush.field_values);

        // console.log('jsonToPush:' ,jsonToPush);
        // this.selectedColumnValues[jsonToPush.field] = '';

        if (jsonToPush.field_values.length === 1) {
          this.tableSelection.tableColumnValues[jsonToPush.field] = jsonToPush.field_values[0].value;
          this.availableColumnValuesWithInitiallyOneChoice.push(jsonToPush.field);
        } else {

          /*
          if (Object.values(this.tableSelection.lastSelections).length > 0) {
            // console.log('lastSelections:', this.tableSelection.tableId, this.tableSelection.lastSelections, this.tableSelection.tableColumnValues, jsonToPush.field, jsonToPush.field_values);
            console.log('lastSelections A:', this.tableSelection.tableId, this.tableSelection.lastSelections, jsonToPush.field, jsonToPush.field_values);

            // let lastValue = this.tableSelection.lastSelections
            if ( Object.keys(this.tableSelection.lastSelections).includes(jsonToPush.field) ) {
              console.log('lastSelections B:', this.tableSelection.tableId, this.tableSelection.lastSelections[jsonToPush.field], jsonToPush.field, jsonToPush.field_values);

              // let lastSelectionFieldValue = jsonToPush.field_values.filter(field_value => {return field_value.value === this.tableSelection.lastSelections[jsonToPush.field]});
              // console.log('lastSections C:', lastSelectionFieldValue);

              console.log('lastSections C:', jsonToPush.field_values.map(field_value => {return field_value.value;}).includes(this.tableSelection.lastSelections[jsonToPush.field]) );
              // als bovenstaande true is, dan kan deze waarde gezet worden ...

              if (jsonToPush.field_values.map(field_value => {return field_value.value;}).includes(this.tableSelection.lastSelections[jsonToPush.field])) {
                console.log('lastSections D')
                this.tableSelection.tableColumnValues[jsonToPush.field] = this.tableSelection.lastSelections[jsonToPush.field];
              }
            }
          }
          */

          if (Object.values(this.tableSelection.lastSelections).length > 0  &&
              Object.keys(this.tableSelection.lastSelections).includes(jsonToPush.field)  &&
              jsonToPush.field_values.map(field_value => {return field_value.value;}).includes(this.tableSelection.lastSelections[jsonToPush.field])
              ) {
            // this field was in previous selection ...
            this.tableSelection.tableColumnValues[jsonToPush.field] = this.tableSelection.lastSelections[jsonToPush.field];
          } else {

            // CHECK if use case, otherwise return empty
            if (this.inputUseCase > -1) {
              // console.log('USE CASE, ', this.inputTableId, jsonToPush.field, jsonToPush.field_values, this.inputUseCaseData.filter(tableObject => {return tableObject.tableName === this.tableSelection.tableName})[0] );
              let useCaseTableInfo = this.inputUseCaseData.filter(tableObject => {
                return tableObject.tableName === this.tableSelection.tableName
              })[0];
              if (typeof useCaseTableInfo !== 'undefined') {
                // console.log('USE CASE TABLE FIELD VALUE', useCaseTableInfo.tableColumnValues[jsonToPush.field], jsonToPush.field_values.map(field => {return field.value;}));
                if (jsonToPush.field_values.map(field => {
                  return field.value;
                }).includes(useCaseTableInfo.tableColumnValues[jsonToPush.field])) {
                  this.tableSelection.tableColumnValues[jsonToPush.field] = useCaseTableInfo.tableColumnValues[jsonToPush.field];
                } else {
                  this.tableSelection.tableColumnValues[jsonToPush.field] = '';
                }
              } else {
                this.tableSelection.tableColumnValues[jsonToPush.field] = '';
              }
            } else {
              this.tableSelection.tableColumnValues[jsonToPush.field] = '';
            }

          }
        }

        this.availableColumnValues.push(jsonToPush);

      });
      this.fillSelections();

      this.checkTableValueSelectionComplete();

    });



  } // END FUNCTION getFieldsForTableForYearAndRegionLevel


  fillSelections() : void {
    // console.log('CALLED fillSelections() ...', this.tableSelection.tableId);
    let selections= {};

    this.tableSelection.lastSelections = {};

    //console.log('columnvaluee START:', this.tableSelection.tableColumnValues);

    this.availableColumnValues.forEach((columnvalue)  => {

      //console.log('columnvaluee:', columnvalue, columnvalue.field, this.tableSelection.tableColumnValues[columnvalue.field]);

      const selectedvalue = columnvalue.field_values.find((field_value: any) => {
        return field_value.value === this.tableSelection.tableColumnValues[columnvalue.field];
      })
      //console.log('columnvaluee selectedvalue:', selectedvalue);
      if (selectedvalue !== undefined) {
        // @ts-ignore
        selections[columnvalue.field_label] = selectedvalue.label;

        this.tableSelection.lastSelections[columnvalue.field] = selectedvalue.value;
      }

    } )
    this.tableSelection.Selections = selections;

    // this.tableSelection.lastSelections = this.tableSelection.Selections;

  }

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
      if (this.tableSelection.tableColumnValues[fieldName].trim() !== ''  &&  this.availableColumnValuesManuallyChanged.includes(fieldName)) {
        selectedJson.push({field: fieldName, value: this.tableSelection.tableColumnValues[fieldName]});
      }
    }
    sourceSelectionJson['selected'] = selectedJson;

    this.featureService.getColumnValuesBySourceJson(this.tableSelection.tableName, JSON.stringify(sourceSelectionJson), this.inputUseCase).subscribe( data => {
      // console.log('getColumnValuesBySourceJson()', data);

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


  changedColumnValue(columnValueField = '') {
    if (!this.availableColumnValuesManuallyChanged.includes(columnValueField)) {
      this.availableColumnValuesManuallyChanged.push(columnValueField);
    }
    // console.log('changedColumnValue()', columnValueField, this.availableColumnValuesManuallyChanged);

    this.getFilteredFieldsForTableForYearAndRegionLevel();

    // this.checkTableValueSelectionComplete();
  } // END FUNCTION changedColumnValue



  checkTableValueSelectionComplete() {
    //console.log('checkTableValueSelectionComplete() ...', this.tableSelection.tableId);

    this.tableSelection.checkSelectionComplete();
    if (this.tableSelection.tableSelectionComplete) {
      this.fillSelections();
    }
    this.emitChangeTableValue();
  } // END FUNCTION checkTableValueSelectionComplete



  checkByClick() {
    console.log('C H E C K  -  checkByClick()', this.otherTableSelection, this.inputOtherTableSelection);

  } // END FUNCTION checkByClick


  // dit hieronder kan waarschijnlijk weer weg als Object.values() niet in html wordt gebruikt ...
  /*
  protected readonly Object = Object;
  */

  showBivariateMap() {
    this.emitChangeTableValue();
  }
} // END CLASS SelectTableValueComponent

