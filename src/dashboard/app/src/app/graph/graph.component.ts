import {Component, Input, OnChanges, SimpleChanges} from '@angular/core';
import {Chart} from "chart.js/auto";

@Component({
  selector: 'app-graph',
  templateUrl: './graph.component.html',
  styleUrl: './graph.component.css'
})
export class GraphComponent implements OnChanges {

  chart: any;

  ngOnChanges(changes: SimpleChanges) {
    // changes.prop contains the old and the new value...

    for (const propName in changes) {
      const chng = changes[propName];
      const cur  = JSON.stringify(chng.currentValue);
      const prev = JSON.stringify(chng.previousValue);
      console.log(`${propName}: currentValue = ${cur}, previousValue = ${prev}`);
      if (propName === 'xydata') {
        console.log('xydata');

      }

    }
  }

  ScatterPlot(info: any) {
    let xydata = info.xydata;
    const ctx = document.getElementById('myChart');
    // @ts-ignore
    if (this.chart) {
      this.chart.destroy();
    }
    const data = {
      datasets: [{
        label: info.xlabel + ' & ' + info.ylabel,
        data: xydata,
        backgroundColor: '#003e5b'
      }],
    };
    // @ts-ignore
    this.chart = new Chart(ctx, {
      type: 'scatter',
      data: data,
      options: {
        scales: {
          x: {
            type: 'linear',
            position: 'bottom',
            title: {text: info.xlabel, display: true}
          },
          y: {
            type: 'linear',
            position: 'bottom',
            title: {text: info.ylabel, display: true}
          }
        }
      }
    });
    //this.chart.update();
  }
}
