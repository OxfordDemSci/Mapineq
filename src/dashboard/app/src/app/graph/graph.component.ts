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

  hightlightPoint(point: any) {
    if (this.chart.data.datasets.length > 1) {
      this.chart.data.datasets.splice(-1);
    }
    let selectedPoint = point;
    let highlight = {
      label: 'Joo',
      backgroundColor: 'rgb(255,255,255)',
      borderColor: 'rgb(219,253,0)',
      borderWidth: 10,
      data: selectedPoint
    };
    this.chart.data.datasets.push(highlight);
    this.chart.update();
  }

  ScatterPlot(info: any) {
    let xydata = info.xydata;
    const context = document.getElementById('myChart');
    // @ts-ignore
    if (this.chart) {
      this.chart.destroy();
    }
    let selectedPoint = xydata.filter((data) =>{
      return data.x === 36903 && data.y === 1.98;
    })
    console.log('selectedPoint', selectedPoint);
    let highlight = {
      label: 'Joo',
      backgroundColor: 'rgb(255,255,255)',
      borderColor: 'rgb(219,253,0)',
      borderWidth: 10,
      data: selectedPoint
    };
    let alldata = {
      label: info.xlabel + ' & ' + info.ylabel,
      data: xydata,
      backgroundColor: '#003e5b'
    }
    console.log('xydata[117]', xydata[117]);
    // let datasets: [
    //   {
    //     label: 'Dataset 1',
    //     data: { x: 2, y: 3 },
    //     borderColor: Utils.CHART_COLORS.red,
    //     backgroundColor: Utils.transparentize(Utils.CHART_COLORS.red, 0.5),
    //   },
    //   {
    //     label: 'Dataset 2',
    //     data: Utils.bubbles(NUMBER_CFG_2),
    //     borderColor: Utils.CHART_COLORS.orange,
    //     backgroundColor: Utils.transparentize(Utils.CHART_COLORS.orange, 0.5),
    //   }
    // ]
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
            min: 0,
            max: 5
          }
        },
        plugins : {
          legend: {
            display: false
          },

        }

      }
    });

    //this.chart.config.datasets[0]['pointBackgroundColor']

    function customRadius( context: any )
    {
      let index = context.dataIndex;

      return index === 3  ?
        80 :
        2;
    }

    function customColor(context) {
      let index = context.dataIndex;
      return index === 3  ? 'rgb(219,253,0)' : '#003e5b';
    }

    //this.chart.update();
  }
}
