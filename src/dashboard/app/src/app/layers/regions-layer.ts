import L from "leaflet";
import {BaseLayer, vectorServer} from "./base-layer";


export class RegionsLayer extends BaseLayer  {

  constructor() {
    super();

  }


  public static getLayer(nutslevel: number, year: number): any {

    //let nutsid = 3;
    let nutsUrl = vectorServer + "areas.get_nuts_areas_tiles" + "/{z}/{x}/{y}.pbf" + "?year=" + year + "&intlevel=" + nutslevel;

    let options = {
      // @ts-ignore
      rendererFactory: L.canvas.tile,
      interactive: true,
      vectorTileLayerStyles: {
        default: {
          weight: 1,
          color: '#da0a0a',
          fill: false,
          fillColor: '#DA0A0AFF',
          fillOpacity: 0.1,
        }
      }
    }
    // @ts-ignore
    return L.vectorGrid.protobuf(nutsUrl, options);


  }



}
