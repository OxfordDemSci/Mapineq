import {Component, OnInit} from '@angular/core';
import {MatFormFieldModule} from "@angular/material/form-field";
import {MatOptionModule} from "@angular/material/core";
import {MatSelectModule} from "@angular/material/select";

import {MapComponent} from "../map/map.component";

import {FeatureService} from "../services/feature.service";


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

  nutsregios: any[] = [];

  tables: DataSource[] = [];
  selectedTable?: DataSource;
  selectedNuts?: any;


  constructor(private featureService: FeatureService) {
  }

  ngOnInit(): void {
    for (let i = 0; i < 4; i++) {
      this.nutsregios.push({'name': "NUTS " + i.toString(), 'value': i});
    }
    for (let i = 2011; i < 2022; i++) {
      this.years.push(i);
      //this.years.push(1992);
    }
    this.tables.push({'table': 'unemployment', 'title' : 'Unemployment %', 'startyear': 2011, 'endyear' : 2022, 'maxvalue': 35});
    this.tables.push({'table': 'peopledensity', 'title' : 'Population Density', 'startyear': 1990, 'endyear' : 2022, 'maxvalue': 1000});
    this.tables.push({'table': 'lifeexpectancy', 'title' : 'Life expectancy', 'startyear': 1990, 'endyear' : 2022, 'maxvalue': 90});
    //this.tables.push({'table': 'xyplot', 'title' : 'X and Y', 'startyear': 1990, 'endyear' : 2022, 'maxvalue': 1000});
    this.selectedTable = this.tables[0];
    this.selectedNuts = this.nutsregios[2];
  }

  selectChange(): void {
    console.log('year', this.selectedYear);
    //this.activateYear(this.selectedYear.toString());
    this.tables = [];
    this.featureService.getSources(this.selectedYear, this.selectedNuts.value).subscribe((data) => {
        data.forEach((d: { [x: string]: any; }) => {
          this.tables.push({
            'table': d['f_resource'],
            'title': d['f_description'],
            'startyear': d['f_startyear'],
            'endyear': d['f_endyear'],
            'maxvalue': d['f_maxvalue'],

          });
        })
      }
    )

  }


  selectTable() {
    console.log('year', this.selectedTable);
  }

  selectNutsChange() {
    console.log('nuts', this.selectedNuts);
  }
}
