import { Component } from '@angular/core';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent {

  cells: any[];


  constructor() {
  } // END FUNCTION constructor

  ngOnInit(): void {

    this.cells = [
      {title: 'Aaa', descr: 'Description A', content: 'Content A'},
      {title: 'Bbb', descr: 'Description B', content: 'Content B'} /* /,
      {title: 'Ccc', descr: 'Description C', content: 'Content C'} /* */
    ];


    document.documentElement.style.setProperty('--select-cell-width', 'calc(100% / ' + this.cells.length.toString() + ')');

  } // END FUNCTION ngOnInit


}
