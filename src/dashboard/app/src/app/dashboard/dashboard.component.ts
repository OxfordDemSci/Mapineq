import { Component } from '@angular/core';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent {

  tableSelections: any[];


  constructor() {
  } // END FUNCTION constructor

  ngOnInit(): void {

    this.tableSelections = [
      {title: 'Aaa', descr: 'Description A', content: 'Content A'},
      {title: 'Bbb', descr: 'Description B', content: 'Content B'} /* /,
      {title: 'Ccc', descr: 'Description C', content: 'Content C'} ,
      {title: 'Ddd', descr: 'Description D', content: 'Content D'} /* */
    ];


    document.documentElement.style.setProperty('--select-cell-width', 'calc(100% / ' + this.tableSelections.length.toString() + ')');

  } // END FUNCTION ngOnInit


}
