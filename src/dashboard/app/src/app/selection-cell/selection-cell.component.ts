import {AfterViewInit, Component, EventEmitter, Input, OnChanges, OnInit, Output, SimpleChanges} from '@angular/core';

@Component({
  selector: 'app-selection-cell',
  templateUrl: './selection-cell.component.html',
  styleUrl: './selection-cell.component.css'
})
export class SelectionCellComponent implements OnInit, AfterViewInit, OnChanges {

  @Input() inputTableId!: any;
  @Input() inputTableSelection!: any;

  @Output() updateTableSelectionFromCell = new EventEmitter();


  tableId: number;
  tableSelection: any;

  constructor() {} // END CONSTRUCTOR

  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {
      // console.log('!!!!! !!!!! !!!!! !!!!! change in', propName, changes[propName].currentValue);
      const change = changes[propName];
      const valueCurrent  = change.currentValue;
      // const valuePrevious = change.previousValue;
      if (propName === 'inputLocationFrom' && valueCurrent) {
        // console.log('setFrom() activated by ngOnChanges', valueCurrent);
      }
    }
  } // END FUNCTION ngOnChanges

  ngOnInit(): void {
    this.tableId = this.inputTableId;
    this.tableSelection = this.inputTableSelection;
  } // END FUNCTION ngOnInit

  ngAfterViewInit() {
  } // END FUNCTION ngAfterViewInit




} // END CLASS SelectionCellComponent
