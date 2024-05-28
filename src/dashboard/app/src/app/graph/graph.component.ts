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

  highlightPoint(point: any) {
    if (this.chart.data.datasets.length > 1) {
      this.chart.data.datasets.splice(-1);
    }
    let selectedPoint = point;
    let highlight = {
      label: 'Joo',
      backgroundColor: 'rgb(255,255,255)',
      borderColor: '#c85a5a',
      borderWidth: 10,
      data: selectedPoint
    };
    this.chart.data.datasets.push(highlight);
    this.chart.update();
  }

  removehighlight() {
    if (this.chart.data.datasets.length > 1) {
      this.chart.data.datasets.splice(-1);
    }
    this.chart.update();
  }

  ScatterPlot(info: any) {
    let xydata = info.xydata;
    const context = document.getElementById('myChart');
    // @ts-ignore
    if (this.chart) {
      this.chart.destroy();
    }
    let alldata = {
      label: info.xlabel + ' & ' + info.ylabel,
      data: xydata,
      backgroundColor: '#003e5b'
    }
    const data = {
      datasets: [alldata],
    };
    // @ts-ignore
    this.chart = new Chart(context, {
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
            title: {text: info.ylabel, display: true},
          }
        },
        plugins : {
          legend: {
            display: false
          },
          title: {
            display: true,
            text: info.xlabel + ' & ' + info.ylabel
          }
        }

      }
    });

  }
}
