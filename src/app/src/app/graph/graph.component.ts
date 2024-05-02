import {Component, Input, OnChanges, SimpleChanges} from '@angular/core';
import {MatIconModule} from "@angular/material/icon";
import {NgForOf} from "@angular/common";
import {Area} from "../map/map.component";
import {DataSource} from "../usercontrols/usercontrols.component";
import {Chart} from "chart.js/auto";
import {FeatureService} from "../services/feature.service";

@Component({
  selector: 'app-graph',
  standalone: true,
    imports: [
        MatIconModule,
        NgForOf
    ],
  templateUrl: './graph.component.html',
  styleUrl: './graph.component.css'
})

export class GraphComponent implements OnChanges  {

  @Input() selectedTable?: DataSource;
  @Input() newarea?: Area;
  areas: Area[] = [];

  chart: any;

  constructor(private featureService: FeatureService) {
  }

  private addGraph(): void {
    const ctx = document.getElementById('myChart');
    // @ts-ignore
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: ['1990', '1991', '1992', '1993', '1994', '1995'],
        datasets: [{
          label: '# of births',
          data: [34000, 19000, 30000, 50000, 20000, 30000],
          borderWidth: 1
        }]
      },
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
  }

  private updateGraph() {
    //let years = Array();
    // @ts-ignore
    this.featureService.getFeaturesByArea(this.areas, this.selectedTable.table).subscribe((data) => {
      let {years, datasets} = this.extracted(data);
      const ctx = document.getElementById('myChart');
      // @ts-ignore
      if (this.chart) {
        this.chart.destroy();
      }
      // @ts-ignore
      this.chart = new Chart(ctx, {
        type: 'line',
        data: {
          labels: years,
          datasets: datasets
        },
        options: {
          scales: {
            y: {
              beginAtZero: true
            }
          }
        }
      });
    });
  }


  private extracted(data: any) {
    let allyears = data.features.map((xx: any) => {
      return xx['properties']['year'];
    });
    let years = allyears.filter((value: any, index: number, array: string | any[]) => array.indexOf(value) === index).sort();
    let properties = data.features.map((xx: any) => {
      return xx['properties'];
    });
    let nuts_ids = this.areas.map((xx: any) => {
      return xx['nuts_id'];
    });
    nuts_ids.sort();
    let end = 0;
    let datasets: { label: string; data: any; }[] = [];
    nuts_ids.forEach((nuts_id, index) => {
      console.log('nuts_id', nuts_id, index);
      let areadata = properties.filter((property: { nuts_id: any; }) => {
        return property.nuts_id === nuts_id;
      })
      let data = areadata.map((row: any) => {
        return {x: row.year, y: row.entity}
      });
      let dataset = {label: nuts_id, data: data};
      datasets.push(dataset);
    })
    return {years, datasets};
  }


  removeArea(nuts_id: string) {
    console.log('remove ', nuts_id);
    this.areas = this.areas.filter((item)=> {
      return item.nuts_id != nuts_id;
    });
    console.log('new array', this.areas);
    if (this.areas.length > 0) {
      this.updateGraph();
    }

  }

  ngOnChanges(changes: SimpleChanges) {
    // changes.prop contains the old and the new value...

    for (const propName in changes) {
      const chng = changes[propName];
      const cur  = JSON.stringify(chng.currentValue);
      const prev = JSON.stringify(chng.previousValue);
      console.log(`${propName}: currentValue = ${cur}, previousValue = ${prev}`);
      if (propName === 'selectedTable') {
        console.log('selectedTable');

      }
      if (propName === 'newarea') {
        if (chng.currentValue !== undefined) {
          this.areas.push(chng.currentValue)
          this.updateGraph();
        }

      }
    }
  }

}
