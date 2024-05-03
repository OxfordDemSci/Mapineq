//
//
// export const vectorServer = "https://mapineqtiles.web.rug.nl/";
// export class BaseLayer extends L.vectorGrid {
//
//   table: string;
//   maxvalue: number = 0;
//
//   constructor(options: {  minZoom?: number, maxZoom?: number, zIndex?: number }, table: string, maxvalue: number) {
//     super(options);
//     this.table = table;
//     this.maxvalue = maxvalue;
//   }
//
//   setMapSource() {
//     super.setSource(new VectorSource({
//       format: new MVT(),
//       url: vectorServer + this.table + "/{z}/{x}/{y}.pbf"
//     }));
//   }
//
//   changeTable(table: string, year: string, maxvalue: number) {
//     this.table = table;
//     this.maxvalue = maxvalue;
//     this.setYear(year);
//
//   }
//
//   setYear(year: string) {
//     super.setSource(new VectorSource({
//       format: new MVT(),
//       url: vectorServer + this.table + "/{z}/{x}/{y}.pbf" + "?filter=year='"+ year +"'"
//     }));
//   }
//
//   setNuts(nutsid: number, year: string) {
//     super.setSource(new VectorSource({
//       format: new MVT(),
//       url: vectorServer + "areas.get_nuts_areas_tiles" + "/{z}/{x}/{y}.pbf" + "?year=" + year + "&intlevel=" + nutsid
//     }));
//   }
// }
