import {BaseLayer} from "./base-layer";
import {Fill, Stroke, Style, Text} from "ol/style";
import {max} from "rxjs";

export class NutsLayer extends BaseLayer {


  constructor(table: string, maxvalue: number) {
    super({
      minZoom: 4,
      zIndex: 70
    }, table,maxvalue);
    this.setStyle(this.nutsStyle);
    this.setMapSource();
  }

  nutsStyle(feature: any) : Style {
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
    if (feature.get('perc_urban')  !== undefined) {
      transparency =  (+feature.get('perc_urban'))/100.0;
      console.log('transparency', transparency);
      label = feature.get('perc_urban');
    }
    return new Style({
      stroke: new Stroke({
        width: 2,
        color: "#8f8787"
      }),
      fill: new Fill({
        color: "rgba(189,12,62, " + transparency + ")"
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
}
