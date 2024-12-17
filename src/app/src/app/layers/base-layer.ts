import VectorTileLayer from "ol/layer/VectorTile";
import VectorSource from "ol/source/VectorTile";
import {MVT} from "ol/format";

export const vectorServer = "https://mapineqtiles.web.rug.nl/";
export class BaseLayer extends VectorTileLayer {

  table: string;
  maxvalue: number = 0;

  constructor(options: {  minZoom?: number, maxZoom?: number, zIndex?: number }, table: string, maxvalue: number) {
    super(options);
    this.table = table;
    this.maxvalue = maxvalue;
  }

  setMapSource() {
    super.setSource(new VectorSource({
      format: new MVT(),
      url: vectorServer + this.table + "/{z}/{x}/{y}.pbf"
    }));
  }

  changeTable(table: string, year: string, maxvalue: number) {
    this.table = table;
    this.maxvalue = maxvalue;
    this.setYear(year);

  }

  setYear(year: string) {
    super.setSource(new VectorSource({
      format: new MVT(),
      url: vectorServer + this.table + "/{z}/{x}/{y}.pbf" + "?filter=year='"+ year +"'"
    }));
  }
}
