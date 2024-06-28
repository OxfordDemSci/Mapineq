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
    // console.log('highlightPoint()', point, this.chart.data);

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


  highlightPointById(id: any) {
    // console.log('highlightPointById()', id, this.chart.data);

    let point = this.chart.data.datasets[0].data.filter(item => {return item.geo === id;});

    // console.log('point:', point);

    if (this.chart.data.datasets.length > 1) {
      this.chart.data.datasets.splice(-1);
    }
    let selectedPoint = point;
    let highlight = {
      label: 'Joo',
      backgroundColor: 'rgb(255,255,255)',
      borderColor: 'rgb(255,192,0)', //'#c85a5a',
      borderWidth: 10,
      data: selectedPoint
    };
    this.chart.data.datasets.push(highlight);
    this.chart.update();
  }



  ScatterPlot(info: any) {
    let color = '#003e5b';
    //console.log('info', info.xydata[22]);
    let xydata = info.xydata;
    const context = document.getElementById('myChart');
    let labels = xydata.map((item) => {return item.geo})
    // @ts-ignore
    if (this.chart) {
      this.chart.destroy();
    }
    let alldata = {
      label: info.xlabel + ' & ' + info.ylabel,
      data: xydata,
      backgroundColor: color
    }
    const data = {
      labels: labels,
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
          },
          tooltip: {
            titleColor: color,
            bodyColor: color,
            backgroundColor: 'rgb(207,206,211)',
            callbacks: {
              label: function(context){
                return [info.xlabel + ': ' + context.parsed.x ,  info.ylabel + ': ' + context.parsed.y];
              }
            }
          }
        }

      }
    });

  }
}
