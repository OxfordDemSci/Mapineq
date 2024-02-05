import VectorTileLayer from "ol/layer/VectorTile";
import VectorSource from "ol/source/VectorTile";
import {MVT} from "ol/format";

export const vectorServer = "https://mapineqtiles.web.rug.nl/";
export class BaseLayer extends VectorTileLayer {

  table:string;


  constructor(options: {  minZoom?: number, maxZoom?: number, zIndex?: number }, table: string) {
    super(options);
    this.table = table;
  }

  setMapSource() {
    super.setSource(new VectorSource({
      format: new MVT(),
      url: vectorServer + this.table + "/{z}/{x}/{y}.pbf"
    }));
  }

  setYear(year: string) {
    super.setSource(new VectorSource({
      format: new MVT(),
      url: vectorServer + this.table + "/{z}/{x}/{y}.pbf" + "?filter=year='"+ year +"'"
    }));
  }
}
