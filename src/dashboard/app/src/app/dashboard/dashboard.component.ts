import {Component, ViewChild} from '@angular/core';
import {ResultMapComponent} from "../result-map/result-map.component";

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent {

  @ViewChild(ResultMapComponent) childResultMap: ResultMapComponent;


  tableSelections: any[];


  panelOpen: boolean;

  constructor() {
  } // END FUNCTION constructor

  ngOnInit(): void {

    this.panelOpen = true;

    this.tableSelections = [
      {title: 'Aaa', descr: 'Description A', content: 'Content A'},
      {title: 'Bbb', descr: 'Description B', content: 'Content B'} /* /,
      {title: 'Ccc', descr: 'Description C', content: 'Content C'} ,
      {title: 'Ddd', descr: 'Description D', content: 'Content D'} /* */
    ];


    // document.documentElement.style.setProperty('--select-cell-width', 'calc(100% / ' + this.tableSelections.length.toString() + ')');

  } // END FUNCTION ngOnInit


  panelToggle(): void {
    this.panelOpen = !this.panelOpen;

  } // END FUNCTION panelToggle

  resizeResultMap(): void {
    this.childResultMap.resizeMap();
  } // END FUNCTION resizeResultMap



}
