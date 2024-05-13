export class DisplayTableValueObject {
    tableId: number;
    tableName: string;
    tableDescr: string;
    tableFunction: string;
    tableYear: string;
    tableRegionLevel: string;
    tableColumnValues: any;

    constructor(jsonObject = {}, index = 0) {
        this.tableId = index;
        this.tableName = '';
        this.tableDescr = '';
        this.tableFunction = '';
        this.tableYear = '-1';
        this.tableRegionLevel = '-1';
        this.tableColumnValues = {};

        for (const field in jsonObject) {
            if(Object.getOwnPropertyNames(this).includes(field)) {
                this[field] = jsonObject[field];
            } else {
                console.log('Non existing property: ', field);
            }
        }
    }

} // END CLASS DisplayTableValueObject
