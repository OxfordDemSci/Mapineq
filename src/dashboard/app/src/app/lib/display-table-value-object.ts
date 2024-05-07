export class DisplayTableValueObject {
    tableName: string;
    tableDescr: string;
    tableFunction: string;

    constructor(jsonObject = {}) {
        this.tableName = '';
        this.tableDescr = '';
        this.tableFunction = '';

        for (const field in jsonObject) {
            this[field] = jsonObject[field];
        }
    }

} // END CLASS DisplayTableValueObject
