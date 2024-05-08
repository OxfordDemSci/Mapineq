export class DisplayTableValueObject {
    tableId: number;
    tableName: string;
    tableDescr: string;
    tableFunction: string;
    tableYear: string;
    tableRegionLevel: string;
    tableFieldName: string;

    constructor(jsonObject = {}, index = 0) {
        this.tableId = index;
        this.tableName = '';
        this.tableDescr = '';
        this.tableFunction = '';
        this.tableYear = '-1';
        this.tableRegionLevel = '-1';
        this.tableFieldName = '';

        for (const field in jsonObject) {
            this[field] = jsonObject[field];
        }
    }

} // END CLASS DisplayTableValueObject
