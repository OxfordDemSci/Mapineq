import {BaseLayer} from "./base-layer";
import {Fill, Stroke, Style, Text} from "ol/style";

export class BirthsLayer extends BaseLayer {

  constructor(table: string, maxvalue: number) {
    super({
      minZoom: 4,
      zIndex: 70
    }, table, maxvalue);
    this.changeStyle();
    //this.setMapSource();
    this.setOpacity(0.8);
  }


  changeStyle() {
    this.setStyle(this.birthsStyle.bind(this));
  }

  birthsStyle(feature: any) : Style {
    let label = ' ';
    if (feature.get('NUTS_NAME') !== undefined) {
      label = feature.get('NUTS_NAME');
      label = '';
    }
    if (feature.get('id') !== undefined) {
      label += ' (' + feature.get('id').toString() + ')';
    }
    //console.log('zoomlevel inside buildingStyle', this.getMapInternal().getView().getZoom());
    // @ts-ignore
    // if ( this.getMapInternal()!.getView().getZoom() < 17.2 || this.getMapInternal()!.getView().getZoom() > 18 ) {
    //   label = '';
    // }
    let transparency = 0;
    //console.log(feature.get('perc_urban'));
    let nrbirths = 0;
    if (feature.get('entity')  !== undefined) {
      //transparency =  (+feature.get('perc_urban'))/100.0;
      //console.log('feature.get(\'entity\')', feature.get('entity'));
      //label = feature.get('entity').toString();
      nrbirths = feature.get('entity');
    }
    let polygoon_color = this.getColor(this.maxvalue, nrbirths);
    return new Style({
      stroke: new Stroke({
        width: 1,
        color: "#8f8787"
      }),
      fill: new Fill({
        //color: "rgba(189,12,62, " + transparency + ")"
        color : polygoon_color,

      }),
      text: new Text({
        text: label, //feature.get('id') !== null ? feature.get('id') : '',
        font: '10px "Open Sans", "Arial Unicode MS", "sans-serif"',
        placement: 'point',
        overflow: true,
        fill: new Fill({
          color: 'black',
        }),
        stroke: new Stroke({
          width: 1,
          color: '#000'
        })
      })
    });
  }

  getColor(max: number | undefined, entity: number): string {

    // @ts-ignore
    const divider = max/7;
    let colors = ['rgb(254,240,217)','rgb(253,212,158)','rgb(253,187,132)',
      'rgb(252,141,89)','rgb(239,101,72)','rgb(215,48,31)','rgb(153,0,0)'];
    let index = Math.ceil(entity/divider);
    //console.log('index=',index);
    return colors[index];
  }
}
