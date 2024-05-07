import {Component, ViewChild} from '@angular/core';
import {ResultMapComponent} from "../result-map/result-map.component";
import {AppVersionAndBuildChecker} from "../lib/app-version-and-build-checker";
import {DisplayObject} from "../lib/display-object";

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent {

  versionChecker: AppVersionAndBuildChecker;


  @ViewChild(ResultMapComponent) childResultMap: ResultMapComponent;


  displayObject: DisplayObject;


  tableSelections: any[];


  panelOpen: boolean;

  constructor() {
    // this.displayObject = new DisplayObject();
  } // END FUNCTION constructor

  ngOnInit(): void {

    this.versionChecker = new AppVersionAndBuildChecker();

    this.panelOpen = true;

    this.tableSelections = [
      {title: 'Aaa', descr: 'Description A', content: 'Content A'},
      {title: 'Bbb', descr: 'Description B', content: 'Content B'} /* /,
      {title: 'Ccc', descr: 'Description C', content: 'Content C'} ,
      {title: 'Ddd', descr: 'Description D', content: 'Content D'} /* */
    ];

    // this.displayObject = new DisplayObject(this.tableSelections);

    this.displayObject = new DisplayObject({tableFields: [{tableName: ''}]});

    // this.displayObject.logConsole();



    // document.documentElement.style.setProperty('--select-cell-width', 'calc(100% / ' + this.tableSelections.length.toString() + ')');

  } // END FUNCTION ngOnInit


  panelToggle(): void {
    this.panelOpen = !this.panelOpen;

  } // END FUNCTION panelToggle

  resizeResultMap(): void {
    this.childResultMap.resizeMap();
  } // END FUNCTION resizeResultMap



}
