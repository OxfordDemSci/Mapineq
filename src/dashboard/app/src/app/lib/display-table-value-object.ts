export class DisplayTableValueObject {
    tableName: string;
    tableDescr: string;
    tableFunction: string;
    tableYear: number;
    tableAreaLevel: number;
    tableFieldName: string;

    constructor(jsonObject = {}) {
        this.tableName = '';
        this.tableDescr = '';
        this.tableFunction = '';
        this.tableYear = -1;
        this.tableAreaLevel = -1;
        this.tableFieldName = '';

        for (const field in jsonObject) {
            this[field] = jsonObject[field];
        }
    }

} // END CLASS DisplayTableValueObject
