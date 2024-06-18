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

    displayDataUpdated: boolean;


    // tableSelections: any[];

    panelOpen: boolean;

    useCase: number;
    useCaseVariant: number;
    useCaseDescr: string;
    useCaseDescrLong: string;
    useCaseData: any;


    constructor(private dashboardFeatureService: FeatureService, private route: ActivatedRoute) {
        // this.displayObject = new DisplayObject();
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
        this.route.paramMap.subscribe(params => {
            if (params.get('id') !== null) {
                console.log('use case:', params.get('id'));

                this.useCase = Number(params.get('id'));

                if (isNaN(this.useCase)) {
                    this.useCase = -1;
                } else {
                    if (params.get('variant') !== null) {
                        this.useCaseVariant = Number(params.get('variant'));
                        if (isNaN(this.useCaseVariant)) {
                            this.useCaseVariant = 0;
                        }
                    }
                    this.showUseCase();
                }

            }
        })

        document.documentElement.style.setProperty('--select-cell-width', 'calc(100% / ' + this.displayObject.tableFields.length.toString() + ')');
        // document.documentElement.style.setProperty('--app-panel-left-width', (500 * this.displayObject.tableFields.length).toString() + 'px');
        document.documentElement.style.setProperty('--app-panel-left-number-selects', this.displayObject.tableFields.length.toString() );

    } // END FUNCTION ngOnInit

    showUseCase(): void {
        // console.log('showUseCase(), id/variant:', this.useCase, this.useCaseVariant);

        this.dashboardFeatureService.getUseCase(this.useCase).subscribe((data) => {
            console.log('showUseCase()', this.useCase, this.useCaseVariant, data);

            if (this.useCaseVariant >= JSON.parse(data[0].f_parameters).length) {
                this.useCaseVariant = 0;
            }


            this.useCaseData = JSON.parse(data[0].f_parameters)[this.useCaseVariant];

            this.useCaseDescr = data[0].f_short_descr;
            this.useCaseDescrLong = data[0].f_long_descr;

            console.log('showUseCase(), useCaseData:', this.useCaseData);

            // console.log('data[0].f_parameters=', JSON.parse(data[0].f_parameters));

            //this.displayObject.tableFields = JSON.parse(data[0].f_parameters);
            //this.displayObject = new DisplayObject({displayType: 'bivariate', formType: "bivariate",
            //    numberTableFields: 2,tableFields:JSON.parse(data[0].f_parameters)});

            // this.updateTableFieldFromSelect(JSON.parse(data[0].f_parameters)[0])
            // this.displayObject.displayTableId = 0;
            // this.updateTableFieldFromSelect(JSON.parse(data[0].f_parameters)[1])


        });


    } // END FUNCTION showUseCase

    panelToggle(): void {
        this.panelOpen = !this.panelOpen;

    } // END FUNCTION panelToggle

    resizeResultMap(): void {
        this.childResultMap.resizeMap();
    } // END FUNCTION resizeResultMap


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

            this.displayObject.tableFields[tableId] = new DisplayTableValueObject(tableField);




            let doCollectDataForSelection = true;
            this.displayObject.tableFields.forEach(tableField => {
                tableField.checkSelectionComplete();
                if (!tableField.tableSelectionComplete) {
                    doCollectDataForSelection = false;
                }
            });

            // console.log(' - - doCollectDataForSelection ???');
            if (doCollectDataForSelection) {
                this.collectDataForSelection(tableId);
            } else {
                this.displayObject['displayData'] = [];
                this.displayDataUpdated = !this.displayDataUpdated;
            }


        }

    } // END FUNCTION updateTableFieldFromSelect


    collectDataForSelection(tableId = 0) {
        //console.log('collectDataForSelection() ... ', tableId);

        if (this.displayObject.displayType === 'bivariate'  &&  this.displayObject.tableFields.length > 1  &&  tableId === 0) {
            // wait for right part ... that one always followes shortly after this ...
            // console.log('collect wait ...', tableId);
        } else {
            // console.log('actually collect', tableId);
            console.log('collectDataForSelection() ... ', tableId);

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

                        this.dashboardFeatureService.getXYData(this.displayObject.tableFields[0].tableRegionLevel, this.displayObject.tableFields[0].tableYear, JSON.stringify(x_json), JSON.stringify(y_json)).subscribe(data => {
                            console.log('A. DISPLAY DATA COLLECTED! (bivariate)', data);
                            this.displayObject['displayData'] = data;
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

                        this.dashboardFeatureService.getXData(this.displayObject.tableFields[tableId].tableRegionLevel, this.displayObject.tableFields[tableId].tableYear, JSON.stringify(x_json)).subscribe(data => {
                            console.log('B. DISPLAY DATA COLLECTED! (univariate)', data);
                            this.displayObject['displayData'] = data;
                            this.displayDataUpdated = !this.displayDataUpdated;
                        });


                    }

                    break;

                default:
                    console.log('NOT IMPLEMENTED YET');
                    break;
            }

        }


    } // END FUNCTION collectDataForSelection



} // END CLASS DashboardComponent
