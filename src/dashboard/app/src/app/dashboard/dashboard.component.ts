import {Component, OnInit, ViewChild} from '@angular/core';
import {ResultMapComponent} from "../result-map/result-map.component";
import {AppVersionAndBuildChecker} from "../lib/app-version-and-build-checker";
import {DisplayObject} from "../lib/display-object";
import {DisplayTableValueObject} from "../lib/display-table-value-object";
import {FeatureService} from "../services/feature.service";
import {ActivatedRoute} from "@angular/router";

@Component({
    selector: 'app-dashboard',
    templateUrl: './dashboard.component.html',
    styleUrl: './dashboard.component.css'
})
export class DashboardComponent implements OnInit{

    versionChecker: AppVersionAndBuildChecker;


    @ViewChild(ResultMapComponent) childResultMap: ResultMapComponent;


    displayObject: DisplayObject;

    displayData: any[];

    displayDataUpdated: boolean;


    // tableSelections: any[];

    panelOpen: boolean;

    showDevInfo: boolean;

    useCase: number;
    useCaseVariant: number;
    useCaseDescr: string;
    useCaseDescrLong: string;
    useCaseData: any;


    constructor(private dashboardFeatureService: FeatureService, private route: ActivatedRoute) {
        // this.displayObject = new DisplayObject();
        this.showDevInfo = false;
        this.displayDataUpdated = false;
        this.panelOpen = false;
        this.useCase = -1;
        this.useCaseVariant = 0;
        this.useCaseDescr = '';
        this.useCaseDescrLong = '';
        this.useCaseData = [];
    } // END FUNCTION constructor

    ngOnInit(): void {

        this.versionChecker = new AppVersionAndBuildChecker();
        this.panelOpen = true;

        // this start values for formType (& displayType) should be set according to use-case ...
        this.displayObject = new DisplayObject({formType: 'bivariate', displayType: 'bivariate', tableFields: [{}, {}]});

        this.checkForQueryValsInUrl();

        document.documentElement.style.setProperty('--select-cell-width', 'calc(100% / ' + this.displayObject.tableFields.length.toString() + ')');
        // document.documentElement.style.setProperty('--app-panel-left-width', (500 * this.displayObject.tableFields.length).toString() + 'px');
        document.documentElement.style.setProperty('--app-panel-left-number-selects', this.displayObject.tableFields.length.toString() );

    } // END FUNCTION ngOnInit

    checkForQueryValsInUrl() {
        /* */
        this.route.paramMap.subscribe(params => {
            if (params.get('id') !== null) {
                console.log('From route paramMap: use case:', params.get('id'));

                this.useCase = Number(params.get('id'));

                if (isNaN(this.useCase)) {
                    this.useCase = -1;
                } else {
                    if (params.get('variant') !== null) {
                        console.log('From route paramMap: variant:', params.get('variant'));
                        this.useCaseVariant = Number(params.get('variant'));
                        if (isNaN(this.useCaseVariant)) {
                            this.useCaseVariant = 0;
                        }
                    }
                    this.showUseCase();
                }

            }
        });
        /* */
        /* */
        let useCaseString = (this.route.snapshot.queryParams['case'] ?? '');
        if (useCaseString.trim() !== ''  &&  !isNaN(Number(useCaseString.trim()))) {
            this.useCase = Number(useCaseString.trim());

            let useCaseVariantString = (this.route.snapshot.queryParams['variant'] ?? '');
            if (useCaseVariantString.trim() !== ''  &&  !isNaN(Number(useCaseVariantString.trim()))) {
                this.useCaseVariant = Number(useCaseVariantString.trim());
            }

            this.showUseCase();
        }


        let tableString = (this.route.snapshot.queryParams['table'] ?? '');
        if (tableString.trim() !== '') {
            let regionString = (this.route.snapshot.queryParams['region'] ?? '');
            this.setTableAndRegion(tableString, regionString);
        }

        console.log('TEST useCase/useCaseVariant: ', this.useCase, this.useCaseVariant);

        // this.urlTo = (this.route.snapshot.queryParams['to'] ?? '').trim();
        /* */

        this.showDevInfo = (typeof this.route.snapshot.queryParams['dev'] === 'string');


    } // END FUNCTION checkForQueryValsInUrl


    updateUseCase() {
        console.log('updateUseCase() ...', this.useCase);


        if (isNaN(this.useCase)  ||  Number(this.useCase) === -1) {
            console.log("AAA");
            this.clearUseCase();
            // this.showUseCase();
        } else {
            console.log("BBB");
            this.showUseCase();
        }

    } // END FUNCTION updateUseCase


    clearUseCase() {
        this.useCase = -1;
        this.useCaseVariant = 0;
        this.useCaseDescr = '';
        this.useCaseDescrLong = '';
        this.useCaseData = [];

        document.getElementById('mapTitle').innerHTML = this.useCaseDescr;
        document.getElementById('mapSubTitle').innerHTML = this.useCaseDescrLong;

        this.displayObject = new DisplayObject({formType: 'bivariate', displayType: 'bivariate', tableFields: [{}, {}]});

    } // END FUNCTION clearUseCase

    showUseCase(): void {
        // console.log('showUseCase(), id/variant:', this.useCase, this.useCaseVariant);

        this.dashboardFeatureService.getUseCase(this.useCase).subscribe((data) => {
            console.log('showUseCase()', this.useCase, this.useCaseVariant, data);
            if (data[0].f_parameters !== null) {
                console.log('number of variants: ', JSON.parse(data[0].f_parameters).length);
                if (this.useCaseVariant >= JSON.parse(data[0].f_parameters).length) {
                    this.useCaseVariant = 0;
                }
                this.useCaseData = JSON.parse(data[0].f_parameters)[this.useCaseVariant];
            }


            this.useCaseDescr = data[0].f_short_descr;
            this.useCaseDescrLong = data[0].f_long_descr;

            console.log('showUseCase(), useCaseData:', this.useCaseData);


            document.getElementById('mapTitle').innerHTML = this.useCaseDescr;
            document.getElementById('mapSubTitle').innerHTML = this.useCaseDescrLong;

            // console.log('data[0].f_parameters=', JSON.parse(data[0].f_parameters));

            //this.displayObject.tableFields = JSON.parse(data[0].f_parameters);
            //this.displayObject = new DisplayObject({displayType: 'bivariate', formType: "bivariate",
            //    numberTableFields: 2,tableFields:JSON.parse(data[0].f_parameters)});

            // this.updateTableFieldFromSelect(JSON.parse(data[0].f_parameters)[0])
            // this.displayObject.displayTableId = 0;
            // this.updateTableFieldFromSelect(JSON.parse(data[0].f_parameters)[1])


        });


    } // END FUNCTION showUseCase

    setTableAndRegion(table: string, region: string): void {
        console.log('table ' + table + ' region ' + region);
        this.displayObject.tableFields[0].tableName = table;
        this.displayObject.tableFields[0].tableRegionLevel = region;

     }

    panelToggle(): void {
        this.panelOpen = !this.panelOpen;

    } // END FUNCTION panelToggle

    panelLeftStatusChange(): void {
        this.childResultMap.resizeMap();
        if (this.panelOpen) {
            this.childResultMap.closeMapInfo();
        } else {
            this.childResultMap.openMapInfo();
        }
    } // END FUNCTION panelLeftStatusChange


    updateTableFieldFromSelect(tableField: DisplayTableValueObject) {
        let tableId = tableField.tableId;

        let showOnlyOneTableId = -1;

        // console.log('=== UPDATE === updateTableFieldFromSelect()', tableId, tableField);


        if (this.displayObject.numberTableFields > 1  &&  tableField.tableShowOnlyThisTable) {
            if (tableField.tableSelectionComplete) {
                console.log('show only table ', tableField.tableId);
                showOnlyOneTableId = tableField.tableId;
                this.displayObject.displayTableId = tableField.tableId;
            }
            tableField.tableShowOnlyThisTable = false;

            this.displayObject.displayType = 'univariate';

            this.collectDataForSelection(showOnlyOneTableId);



        } else {

            this.displayObject.displayType = this.displayObject.formType;
            this.displayObject.displayTableId = -1;

            if (tableField.tableId === 0 && this.displayObject.formType === 'bivariate') {
                this.displayObject.tableFields[1].tableRegionLevel = this.displayObject.tableFields[0].tableRegionLevel;
                this.displayObject.tableFields[1].tableYear = this.displayObject.tableFields[0].tableYear;
                if (this.displayObject.tableFields[0].tableName === '') {
                    this.displayObject.tableFields[1].tableName = '';
                }
            }

            // console.log('CHECK HIER???');
            this.displayObject.tableFields[tableId] = new DisplayTableValueObject(tableField);




            let doCollectDataForSelection = false;
            if (this.displayObject.tableFields.length > 0) {
                doCollectDataForSelection = true;
                this.displayObject.tableFields.forEach(tableField => {
                    tableField.checkSelectionComplete();
                    if (!tableField.tableSelectionComplete) {
                        doCollectDataForSelection = false;
                    }
                });
            }

            // console.log(' - - doCollectDataForSelection ???');
            if (doCollectDataForSelection) {
                this.collectDataForSelection(tableId);
                // SJOERD: tijdelijk UIT gezet
            } else {
                // this.displayObject['displayData'] = [];
                this.displayData = [];
                this.displayDataUpdated = !this.displayDataUpdated;
            }


        }

    } // END FUNCTION updateTableFieldFromSelect


    checkShowOnMapDisabled() {
        switch(this.displayObject.formType) {
            case 'bivariate':
                if (this.displayObject.tableFields.length > 1  &&  this.displayObject.tableFields[0].tableSelectionComplete  &&  this.displayObject.tableFields[1].tableSelectionComplete) {
                    return false;
                } else {
                    return true;
                }
                break;

            default:
                console.log('checkShowOnMapDisabled(), NOT IMPLEMENTED YET (formtype: ' + this.displayObject.formType.toString() + ')');
                return true;
                break;
        }

    } // END FUNCTION checkShowOnMapDisabled

    showBivariateMap() {
        console.log('CALLED showBivariateMap() ...');

        this.displayObject.displayType = 'bivariate';
        this.displayObject.displayTableId = -1;

        this.collectDataForSelection(1);
    } // END FUNCTION showBivariateMap



    collectDataForSelection(tableId = 0) {
        console.log('CALLED collectDataForSelection() ... ', tableId);

        // if (this.displayObject.displayType === 'bivariate'  &&  this.displayObject.tableFields.length > 1  &&  tableId === 0) {
        if (tableId === 999) {
            // wait for right part ... that one always followes shortly after this ...
            console.log('collect wait .', tableId);
        } else {
            // console.log('actually collect', tableId);
            console.log('collect START ... ', tableId);

            // this.displayObject = new DisplayObject(this.displayObject);

            switch(this.displayObject.formType) {
                case 'bivariate':

                    if (this.displayObject.displayType === 'bivariate') {
                        let x_json = {};
                        let y_json = {};

                        x_json['source'] = this.displayObject.tableFields[0].tableName;
                        let x_conditions = [];
                        for (const fieldName in this.displayObject.tableFields[0].tableColumnValues) {
                            x_conditions.push({
                                field: fieldName,
                                value: this.displayObject.tableFields[0].tableColumnValues[fieldName]
                            });
                        }
                        x_json['conditions'] = x_conditions;

                        y_json['source'] = this.displayObject.tableFields[1].tableName;
                        let y_conditions = [];
                        for (const fieldName in this.displayObject.tableFields[1].tableColumnValues) {
                            y_conditions.push({
                                field: fieldName,
                                value: this.displayObject.tableFields[1].tableColumnValues[fieldName]
                            });
                        }
                        y_json['conditions'] = y_conditions;

                        //console.log('before abc    NET VOOR AANROEP getXYData (bivariate versie)');
                        this.dashboardFeatureService.getXYData(this.displayObject.tableFields[0].tableRegionLevel, this.displayObject.tableFields[0].tableYear, JSON.stringify(x_json), JSON.stringify(y_json)).subscribe(data => {
                            //console.log('before abc    A. DISPLAY DATA COLLECTED! (bivariate)', data);
                            // this.displayObject['displayData'] = data;
                            this.displayData = data;
                            this.displayDataUpdated = !this.displayDataUpdated;
                        });
                    } else {
                        // SHOW ONLY ONE TABLE

                        let x_json = {};

                        x_json['source'] = this.displayObject.tableFields[tableId].tableName;
                        let x_conditions = [];
                        for (const fieldName in this.displayObject.tableFields[tableId].tableColumnValues) {
                            x_conditions.push({
                                field: fieldName,
                                value: this.displayObject.tableFields[tableId].tableColumnValues[fieldName]
                            });
                        }
                        x_json['conditions'] = x_conditions;

                        console.log('NET VOOR AANROEP getXData (UNI versie)');
                        this.dashboardFeatureService.getXData(this.displayObject.tableFields[tableId].tableRegionLevel, this.displayObject.tableFields[tableId].tableYear, JSON.stringify(x_json)).subscribe(data => {
                            //console.log('before abc    B. DISPLAY DATA COLLECTED! (univariate)', data);
                            // this.displayObject['displayData'] = data;
                            this.displayData = data;
                            this.displayDataUpdated = !this.displayDataUpdated;
                        });


                    }

                    break;

                default:
                    console.log('NOT IMPLEMENTED YET (formtype: ' + this.displayObject.formType.toString() + ')');
                    break;
            }

        }


    } // END FUNCTION collectDataForSelection
    downloadUrl: any;


    downloadCSV() {

        //this.displayObject.displayData;
        // let csv = this.createCSV(this.displayObject.displayData);
        let csv = this.createCSV(this.displayData);
        const blob = new Blob([csv], { type: 'text/csv' });

        // Create a URL for the Blob

        this.downloadUrl = URL.createObjectURL(blob);
    }


    createCSV(data: any[]) {

        // Empty array for storing the values
        let csvRows = [];

        // Headers is basically a keys of an object which
        // is id, name, and profession
        const headers = Object.keys(data[0]);

        // As for making csv format, headers must be
        // separated by comma and pushing it into array
        let displayHeaders = Object.keys(data[0]);
        displayHeaders[3] = this.displayObject.tableFields[0].tableDescr;
        displayHeaders[4] = this.displayObject.tableFields[1].tableDescr;
        csvRows.push(displayHeaders.join(','));

        // Pushing Object values into the array with
        // comma separation

        // Looping through the data values and make
        // sure to align values with respect to headers
        for (const row of data) {
            const values = headers.map(e => {
                return row[e];
            })
            for (let i = 0; i< values.length; i++) {
                if (typeof values[i] === 'string') {
                    values[i] = values[i].replaceAll(',', ' ');
                }
            }
            csvRows.push(values.join(','));
        }

        // returning the array joining with new line
        return csvRows.join('\n');
    }


} // END CLASS DashboardComponent
