import {Component, OnInit} from '@angular/core';
import {MatFormFieldModule} from "@angular/material/form-field";
import {MatOptionModule} from "@angular/material/core";
import {MatSelectModule} from "@angular/material/select";

import {MapComponent} from "../map/map.component";


export interface DataSource {
  table: string;
  title: string;
  startyear: number;
  endyear: number;
  maxvalue: number;
}


@Component({
  selector: 'app-usercontrols',
  standalone: true,
  imports: [
    MatFormFieldModule,
    MatOptionModule,
    MatSelectModule,
    MapComponent
  ],
  templateUrl: './usercontrols.component.html',
  styleUrl: './usercontrols.component.css'
})

export class UsercontrolsComponent implements OnInit {

  years: number[] = [];
  selectedYear = 2015;

  tables: DataSource[] = [];
  selectedTable?: DataSource;

  ngOnInit(): void {

    for (let i = 2011; i < 2022; i++) {
      this.years.push(i);
      //this.years.push(1992);
    }
    this.tables.push({'table': 'unemployment', 'title' : 'Unemployment %', 'startyear': 2011, 'endyear' : 2022, 'maxvalue': 35});
    this.tables.push({'table': 'peopledensity', 'title' : 'Population Density', 'startyear': 1990, 'endyear' : 2022, 'maxvalue': 1000});
    this.tables.push({'table': 'xyplot', 'title' : 'X and Y', 'startyear': 1990, 'endyear' : 2022, 'maxvalue': 1000});
    this.selectedTable = this.tables[0];

  }

  selectChange(): void {
    console.log('year', this.selectedYear);
    //this.activateYear(this.selectedYear.toString());
  }


  selectTable() {
    console.log('year', this.selectedTable);
  }
}
