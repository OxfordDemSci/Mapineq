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

  @Output() updateRegionLevelFromSelect = new EventEmitter();

  intervalTimers: any[];

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

    this.intervalTimers = [];

  } // END CONSTRUCTOR


  ngOnInit(): void {
    console.log('ngOnInit() select-table-value.component.ts ... tableId: ', this.inputTableId);




    this.tableId = this.inputTableId;

    this.tableSelection = this.inputTableSelection;
    this.otherTableSelection = this.inputOtherTableSelection;

    //console.log('before abc ngOnInit ...', this.tableSelection.tableId);

    /*
    // this.setAvailableRegionLevels();
    setTimeout( () => {
      // little timeout to make sure this.tableSelect
      this.setAvailableRegionLevels();
    }, 500);
    */
    if (this.inputUseCase < 0) {
      this.setAvailableRegionLevels();
    } else {
      console.log('Case study ' + this.inputUseCase.toString() + ', start interval ...', this.tableId, this.inputUseCaseData.length);
      this.intervalTimers['regionLevels_' + this.tableId.toString()] = setInterval( () => {
        if (this.inputUseCaseData.length > 0) {
          console.log(' - Case study ... GO!!', this.tableId);
          this.setAvailableRegionLevels();
          clearInterval(this.intervalTimers['regionLevels_' + this.tableId.toString()]);
        } else {
          console.log(' - Case study ... WAIT', this.tableId);
        }
      }, 100);
    }


    // this.setTableSources(); // KAN UIT?

    // this.componentInitiated = true;
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

      /* SJOERD
      if (propName === 'inputTableSelection' && valueCurrent) {
        // DEZE REGEL HIERONDER MISTE ...
        //console.log('before abc - ngOnChanges(), "inputTableSelection":', this.tableSelection.tableId);
        this.tableSelection = this.inputTableSelection;
        // this.checkTableValueSelectionComplete(); // deze _hier_ aanroepen zorgt dat hij blijft checken en niet (kaart) plot
      }
      */

      /* SJOERD
      if (propName === 'inputOtherTableSelection' && valueCurrent  &&  this.componentInitiated) {
      // if (propName === 'inputOtherTableSelection' && valueCurrent  &&  this.componentInitiated  &&  this.inputUseCase === -1) {
        // console.log('ngOnChanges(), "inputOtherTableSelection":', valueCurrent);

        //console.log('before abc - ngOnChanges(), "inputOtherTableSelection" CHECK:', this.inputTableId, this.inputUseCase, this.useCaseOtherTableLoaded, this.inputOtherTableSelection.tableName, this.tableSelection.tableName);
        if (this.inputUseCase === -1  ||  this.useCaseOtherTableLoaded < 3) {
          console.log('before abc - ngOnChanges(), "inputOtherTableSelection", inputTableId', this.inputTableId, this.componentInitiated, this.inputOtherTableSelection.tableName, this.tableSelection.tableName, this.inputUseCaseData);
          this.otherTableSelection = this.inputOtherTableSelection;
          this.setTableSources();
          this.useCaseOtherTableLoaded++;
        }
        if (this.inputOtherTableSelection.tableName === '') {
          this.useCaseOtherTableLoaded = 0; // SJO 20240909
        }
      }
      */

      if (propName === 'region'  &&  this.componentInitiated) {
        // console.log('********** change in', propName, changes[propName].currentValue, changes[propName].previousValue, this.tableSelection.tableId, (this.tableSelection.tableId === 0 ? 'LEFT' : 'RIGHT'), this.componentInitiated, this.tableId);
        /* SJOERD
        this.tableId = 0;
        */
        this.tableSelection.tableRegionLevel = changes[propName].currentValue;

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
    //console.log('- setAvailableRegionLevels(), tableId:', this.tableId, ', inputUseCase: ', this.inputUseCase.toString(),  ', inputUseCaseData.length: ',  this.inputUseCaseData.length.toString(), ' - - - - -');

    // here instead of in ngOnInit ...
    this.componentInitiated = true;

    this.featureService.getNutsLevels(this.inputUseCase).subscribe( data => {
      //console.log('A setAvailableRegionLevels(), usecase/data:', this.inputUseCase, data);
      this.availableRegionLevels = data.map((item) => {return item.f_level;});
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
    // console.log('SJOERD regionLevelChanged() ...', this.tableSelection.tableId, this.tableId, (this.tableSelection.tableId === 0 ? 'LEFT' : 'RIGHT'));

    // HIERONDER WSS ook iets doen in geval van tableId === 1, obv regionAanpassing (in predictor)
    if (this.tableId === 0) {
      // this.tableSelection.tableRegionLevel = this.otherTableSelection.tableRegionLevel;
      // this.otherTableSelection.tableRegionLevel = this.tableSelection.tableRegionLevel;
      /* SJOERD
      this.tableSelection.tableName = ''; // necessary to clear table if data unavailable for chosen level
      this.updateTableValueFromSelect.emit(this.tableSelection);
      */
      this.updateRegionLevelFromSelect.emit(this.tableSelection.tableRegionLevel);

      //this.otherTableSelection.tableRegionLevel = this.tableSelection.tableRegionLevel;

    }

    /* SJOERD
    this.setTableSources();
    */

  } // END FUNCTION regionLevelChanged


  setTableSources() {
    //console.log('vlak voor getSources, tableId:', this.tableId);

    console.log('setTableSources() ...', this.tableSelection.tableId, (this.tableSelection.tableId === 0 ? 'LEFT' : 'RIGHT'));
    /*
    if (this.tableId === 0) {
    */
    if (true) {

      /* SJOERD */
      this.tableSelectClearSelectedOption();
      // this.tableSelection.tableName = '';
      // this.tableSelection.tableColumnValues = {};
      // this.tableSelection.Selections = {};
      /* */

      // this.featureService.getAllSources().subscribe((data) => {
      this.featureService.getResourceByNutsLevel(this.tableSelection.tableRegionLevel, this.inputUseCase, this.tableSelection.tableId).subscribe((data) => {
        // this.tables = data;
        this.tableSelectOptions = data;

        this.availableTableNames = data.map( dataItem => {return dataItem.f_resource});

        this.tableSelectFilteredOptions = this.tableSelectFormControl.valueChanges.pipe(
            startWith(''),
            map(value => this.filterTableSelectOptions(value || '')),
        );
        if (this.region !== '') {
          // console.log('this.region', this.region, this.tableSelection.tableName, this.tableSelection.lastTableName);
          /* SJOERD
          if (this.availableTableNames.includes(this.tableSelection.tableName)) {
          */
          if (this.availableTableNames.includes(this.tableSelection.lastTableName)) {
            // console.log('TABLENAME setten', this.inputTableId);
            // this.tableSelection.tableName = this.inputUseCaseData[this.inputTableId].tableName;

            let selectedTableObject = this.tableSelectOptions.filter( tableObject => {
              /* SJOERD
              return tableObject.f_resource === this.tableSelection.tableName;
              */
              return tableObject.f_resource === this.tableSelection.lastTableName;
            })

            //console.log('before abc A - selectedTableObject: ', this.tableSelection.tableId, selectedTableObject);
            this.tableSelectOption(selectedTableObject[0]);

          } else {
            // console.log('CHECKPOINT Y:', this.tableId, this.tableSelection.tableName);

            this.tableSelection.tableName = '';
            this.tableSelection.tableDescr = '';
            this.tableSelection.tableColumnValues = {};
            this.availableColumnValues = [];
            this.availableYears = [];

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

        // console.log('CHECKPOINT X', this.tableSelection.tableId, this.tableSelection, this.tableSelection.tableName);


      });
    } /* else if (this.tableId === 1) {
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
          this.availableYears = [];
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

        // console.log('CHECKPOINT X', this.tableSelection.tableId, this.tableSelection, this.tableSelection.tableName);


      });
    }
    */



  } // END FUNCTION setTableSources


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
    this.tableSelection.tableShortDescr = selectedOption.f_short_description;
    this.tableSelection.lastTableName = this.tableSelection.tableName;

    // this.emitChangeTableValue();


    /*
    if (this.tableSelection.tableId !== 1) {
      this.tableSelection.tableYear = '';
      // this.tableSelection.tableRegionLevel = '';
    } else {
      this.tableSelection.tableYear = this.otherTableSelection.tableYear;
      this.tableSelection.tableRegionLevel = this.otherTableSelection.tableRegionLevel;
    }
    */
    // this.tableSelection.tableYear = '';
    /* 20250224 TURN OFF DIFFERENT YEARS, UNNECESSARY CODE??? /
    if (this.tableSelection.tableId === 1) {
      this.tableSelection.tableRegionLevel = this.otherTableSelection.tableRegionLevel;
    }
    /* */

    this.availableYearsAndRegionLevels = [];
    this.availableYears = [];

    // this.availableRegionLevels = [];

    // console.log('before this.featureService.getInfoByReSource()', this.tableSelection.tableId, this.tableSelection.tableName);
    this.featureService.getInfoByReSource(this.tableSelection.tableName, this.inputUseCase).subscribe( data => {
      this.availableYearsAndRegionLevels = data;
      // console.log('SJOERD 0001', this.tableSelection.tableId, 'last:', this.tableSelection.lastTableYear, 'new/current:', this.tableSelection.tableYear);
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

    });


    /* 20250224 TURN OFF DIFFERENT YEARS, because year might not be known yet, because not depending on predictor year ... /
    if (this.tableSelection.tableId === 1) {
      // this.checkTableValueSelectionComplete(); // SJO 20240903 DEZE MSS OVERBODIG?
      this.getFieldsForTableForYearAndRegionLevel();
    }
    /* */

    this.emitChangeTableValue();

  } // END FUNCTION tableSelectOption



  tableSelectClearSelectedOption(autoComplete = null) {
    //console.log('before abc tableSelectClearSelectedOption() ...', this.inputTableId);

    // console.log('SJOERD 0004', this.tableSelection.tableId, 'last:', this.tableSelection.lastTableYear, 'new/current:', this.tableSelection.tableYear)
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


    if (autoComplete !== null) {
      // console.log('CHECK: ', autoComplete.options);
      autoComplete.options.forEach(option => {
        option.deselect();
      });
    }

    this.tableSelectFormControl.reset('');

    this.checkTableValueSelectionComplete();

    if (this.tableSelection.tableId === 0  &&  this.inputUseCase > -1) {
      //console.log('before abc  RESET ...');
      // this.useCaseOtherTableLoaded = 0; // ANDERE useCaseOtherTableLoaded zou weer op nul moeten worden gezet ...
    }

    this.emitChangeTableValue();
  } // END FUNCTION tableSelectClearSelectedOption


  tableSelectClearChosenColumnValues() {
    // console.log('tableSelectClearChosenColumnValues() CALLED ...', this.tableSelection.tableColumnValues, this.availableColumnValuesWithInitiallyOneChoice);

    for( const property in this.tableSelection.tableColumnValues ) {
        // console.log('item: ', property, this.tableSelection.tableColumnValues[property], !this.availableColumnValuesWithInitiallyOneChoice.includes(property));
        if ( !this.availableColumnValuesWithInitiallyOneChoice.includes(property) ) {
          this.tableSelection.tableColumnValues[property] = '';
        }
    }

    // console.log('tableSelectClearChosenColumnValues() IN BETWEEN:', this.tableSelection.tableColumnValues, this.availableColumnValuesWithInitiallyOneChoice);

    //this.getFieldsForTableForYearAndRegionLevel(); // this collects the default case study values (and won't work with new select/input version)
    this.getFilteredFieldsForTableForYearAndRegionLevel();

    // console.log('tableSelectClearChosenColumnValues() END FUNCTION:', this.tableSelection.tableColumnValues, this.availableColumnValuesWithInitiallyOneChoice);


  } // END FUNCTION tableSelectClearChosenColumnValues

  showOnlyThisTableOnMap() {
    this.tableSelection.tableShowOnlyThisTable = true;
    this.emitChangeTableValue();
  } // END FUNCTION showOnlyThisTableOnMap



  emitChangeTableValue() {
    // console.log('emitChangeTableValue() .. id:', this.tableSelection.tableId, (this.tableSelection.tableId === 0 ? 'LEFT' : 'RIGHT'));
    this.updateTableValueFromSelect.emit(this.tableSelection);
  }



  setAvailableYears() {
    // console.log('CALLED setAvailableYears() ... ', this.tableSelection.tableId, JSON.stringify(this.availableYearsAndRegionLevels));

    this.availableYears = [];

    this.availableYearsAndRegionLevels.forEach( row => {
      // only add years with correct (chosen) level
      if (row.f_level === this.tableSelection.tableRegionLevel  &&  !this.availableYears.includes(row.f_year)) {
        this.availableYears.push(row.f_year);
      }
    })

    this.availableYears.sort();
    this.availableYears.reverse();

    // console.log('SJOERD 0002', this.tableSelection.tableId, 'last:', this.tableSelection.lastTableYear, 'new/current:', this.tableSelection.tableYear);
    if (this.tableSelection.lastTableYear !== ''  &&  this.availableYears.includes(this.tableSelection.lastTableYear)) {
      this.tableSelection.tableYear = this.tableSelection.lastTableYear;
      this.getFieldsForTableForYearAndRegionLevel();
    } else {
      if (this.inputUseCase > -1 && this.inputTableId === 0) {
        // console.log('CHECK YEAR: ', this.inputUseCaseData[this.inputTableId]);
        if (this.availableYears.includes(this.inputUseCaseData[this.inputTableId].tableYear)) {
          this.tableSelection.tableYear = this.inputUseCaseData[this.inputTableId].tableYear;
          this.getFieldsForTableForYearAndRegionLevel();
        } else {
          // this should never happen ...
          this.tableSelection.tableYear = this.availableYears[0];
          this.getFieldsForTableForYearAndRegionLevel();
        }
      } else {
        this.tableSelection.tableYear = this.availableYears[0];
        this.getFieldsForTableForYearAndRegionLevel();
      }
    }

    // console.log('availableYears: ', this.availableYears);
  } // END FUNCTION setAvailableYears

  /*
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

    // SJOERD: 20250219 waarom dit alleen bij 1?
    if (this.tableSelection.tableId === 1) {
      this.getFieldsForTableForYearAndRegionLevel();
    }

    // console.log('availableRegionLevels: ', this.availableRegionLevels);
  } // END FUNCTION setAvailableRegionLevelsForYear
  */


  getFieldsForTableForYearAndRegionLevel() {
    // console.log(' >>> >>>  getFieldsForTableForYearAndRegionLevel(), tableId', this.tableSelection.tableId);
    // console.trace('TRACE0', this.tableSelection.tableId);
    //console.log('getFieldsForTableForYearAndRegionLevel(), year, regionLevel', this.tableSelection.tableYear, this.tableSelection.tableRegionLevel);
    this.availableColumnValues = [];
    this.availableColumnValuesWithInitiallyOneChoice = [];
    this.availableColumnValuesManuallyChanged = [];
    // this.selectedColumnValues = {};
    this.tableSelection.tableColumnValues = {};


    document.getElementById('divTableDescr_' + this.tableSelection.tableId.toString()).classList.add('divLoading');

    // console.log('SJOERD 0003', this.tableSelection.tableId, 'last:', this.tableSelection.lastTableYear, 'new/current:', this.tableSelection.tableYear);
    this.tableSelection.lastTableYear = this.tableSelection.tableYear;



    // this.emitChangeTableValue(); // SJO 20240903 - MSS OVERBODIG ??


    let sourceSelectionJson = {};
    sourceSelectionJson['year'] = this.tableSelection.tableYear;
    sourceSelectionJson['level'] = this.tableSelection.tableRegionLevel;

    let selectedJson = []
    sourceSelectionJson['selected'] = selectedJson;

    // console.log('SJOERD 0003-1', this.tableSelection.tableId);
    this.featureService.getColumnValuesBySourceJson(this.tableSelection.tableName, JSON.stringify(sourceSelectionJson), this.inputUseCase).subscribe( data => {
      // this.featureService.getColumnValuesBySource(this.tableSelection.tableName, this.tableSelection.tableYear, this.tableSelection.tableRegionLevel).subscribe( data => {
      // console.log('getColumnValuesBySource()', this.tableSelection.tableName, this.tableSelection.tableYear, this.tableSelection.tableRegionLevel, data);

      this.availableColumnValues = [];
      this.availableColumnValuesWithInitiallyOneChoice = [];
      this.availableColumnValuesManuallyChanged = [];
      // this.selectedColumnValues = new Array(data.length).fill('');

      // console.log('data:', data.length.toString(), JSON.stringify(data));



      data.forEach( row => {
        // console.log('data.forEach, row:', this.tableSelection.tableId, row);
        let jsonToPush = row;

        // console.log('jsonToPush:' ,jsonToPush);
        // this.selectedColumnValues[jsonToPush.field] = '';

        if (jsonToPush.field_values !== null) {
          if (jsonToPush.field_values.length === 1) {
            this.tableSelection.tableColumnValues[jsonToPush.field] = jsonToPush.field_values[0].value;
            this.availableColumnValuesWithInitiallyOneChoice.push(jsonToPush.field);
          } else {


            if (Object.values(this.tableSelection.lastSelections).length > 0 &&
              Object.keys(this.tableSelection.lastSelections).includes(jsonToPush.field) &&
              jsonToPush.field_values.map(field_value => {
                return field_value.value;
              }).includes(this.tableSelection.lastSelections[jsonToPush.field])
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
        }

        this.availableColumnValues.push(jsonToPush);

      });

      // console.log('SJOERD 0003a', this.tableSelection.tableId);
      this.fillSelections();

      // console.log('SJOERD 0003b', this.tableSelection.tableId);
      this.checkTableValueSelectionComplete();

      // console.log('SJOERD 0003c', this.tableSelection.tableId);
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

    document.getElementById('divTableDescr_' + this.tableSelection.tableId.toString()).classList.add('divLoading');

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

        if (jsonToPush.field_values.length === 1) {
          this.tableSelection.tableColumnValues[jsonToPush.field] = jsonToPush.field_values[0].value;
        }

        this.availableColumnValues.push(jsonToPush);
      });


      this.checkTableValueSelectionComplete();


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

    document.getElementById('divTableDescr_' + this.tableSelection.tableId.toString()).classList.remove('divLoading');


    this.tableSelection.checkSelectionComplete();
    if (this.tableSelection.tableSelectionComplete) {
      this.fillSelections();
    }
    this.emitChangeTableValue();
  } // END FUNCTION checkTableValueSelectionComplete



  checkByClick() {
    console.log('C H E C K  -  checkByClick()', this.otherTableSelection, this.inputOtherTableSelection);

  } // END FUNCTION checkByClick



  showBivariateMap() {
    this.emitChangeTableValue();
  }
} // END CLASS SelectTableValueComponent

