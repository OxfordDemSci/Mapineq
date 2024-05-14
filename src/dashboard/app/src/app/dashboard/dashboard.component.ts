import {Component, ViewChild} from '@angular/core';
import {ResultMapComponent} from "../result-map/result-map.component";
import {AppVersionAndBuildChecker} from "../lib/app-version-and-build-checker";
import {DisplayObject} from "../lib/display-object";
import {DisplayTableValueObject} from "../lib/display-table-value-object";
import {FeatureService} from "../services/feature.service";

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent {

  versionChecker: AppVersionAndBuildChecker;


  @ViewChild(ResultMapComponent) childResultMap: ResultMapComponent;


  displayObject: DisplayObject;


  // tableSelections: any[];


  panelOpen: boolean;

  constructor(private dashboardFeatureService: FeatureService) {
    // this.displayObject = new DisplayObject();
  } // END FUNCTION constructor

  ngOnInit(): void {

    this.versionChecker = new AppVersionAndBuildChecker();

    this.panelOpen = true;

    /*
    this.tableSelections = [
      {title: 'Aaa', descr: 'Description A', content: 'Content A'},
      {title: 'Bbb', descr: 'Description B', content: 'Content B'} //,
      // {title: 'Ccc', descr: 'Description C', content: 'Content C'} ,
      // {title: 'Ddd', descr: 'Description D', content: 'Content D'}
    ];
    this.displayObject = new DisplayObject(this.tableSelections);
    document.documentElement.style.setProperty('--select-cell-width', 'calc(100% / ' + this.tableSelections.length.toString() + ')');
    */


    this.displayObject = new DisplayObject({displayType: 'bivariate', tableFields: [{}, {}]});
    // this.displayObject = new DisplayObject({displayType: 'choropleth', tableFields: [{}, {}]});

    // this.displayObject.logConsole();

    document.documentElement.style.setProperty('--select-cell-width', 'calc(100% / ' + this.displayObject.tableFields.length.toString() + ')');
    // document.documentElement.style.setProperty('--app-panel-left-width', (500 * this.displayObject.tableFields.length).toString() + 'px');
    document.documentElement.style.setProperty('--app-panel-left-number-selects', this.displayObject.tableFields.length.toString() );

  } // END FUNCTION ngOnInit


  panelToggle(): void {
    this.panelOpen = !this.panelOpen;

  } // END FUNCTION panelToggle

  resizeResultMap(): void {
    this.childResultMap.resizeMap();
  } // END FUNCTION resizeResultMap


  updateTableFieldFromSelect(tableField: DisplayTableValueObject) {
    let tableId = tableField.tableId;

    // console.log('=== UPDATE === updateTableFieldFromSelect()', tableId, tableField);


    this.displayObject.tableFields[tableId] = new DisplayTableValueObject(tableField);


    if (tableField.tableId === 0  &&  this.displayObject.displayType === 'bivariate') {
      this.displayObject.tableFields[1].tableRegionLevel = this.displayObject.tableFields[0].tableRegionLevel;
      this.displayObject.tableFields[1].tableYear = this.displayObject.tableFields[0].tableYear;
      if (this.displayObject.tableFields[0].tableName === '') {
        this.displayObject.tableFields[1].tableName = '';
      }
    }

    let doCollectDataForSelection = true;
    this.displayObject.tableFields.forEach( tableField => {
      tableField.checkSelectionComplete();
      if (!tableField.tableSelectionComplete) {
        doCollectDataForSelection = false;
      }
    });

    // console.log(' - - doCollectDataForSelection ???');
    if (doCollectDataForSelection) {
      this.collectDataForSelection(tableId);
    }

  } // END FUNCTION updateTableFieldFromSelect


  collectDataForSelection(tableId = 0) {
    //console.log('collectDataForSelection() ... ', tableId);

    if (this.displayObject.tableFields.length > 1  &&  tableId === 0) {
      // wait for right part ... that one always followes shortly after this ...
      // console.log('collect wait ...', tableId);
    } else {
      // console.log('actually collect', tableId);
      console.log('collectDataForSelection() ... ', tableId);

      switch(this.displayObject.displayType) {
        case 'bivariate':
          this.dashboardFeatureService.getResourceByNutsLevel(this.displayObject.tableFields[0].tableRegionLevel).subscribe( data => {
            this.displayObject.displayData = data;
          });
          break;
        default:
          console.log('NOT IMPLEMENTED YET');
          break;
      }

    }


    } // END FUNCTION collectDataForSelection



} // END CLASS DashboardComponent
