export class DisplayTableValueObject {
    tableName: string;
    tableFunction: string;

    constructor(jsonObject = {}) {
        this.tableName = '';
        this.tableFunction = '';

        for (const field in jsonObject) {
            this[field] = jsonObject[field];
        }
    }

} // END CLASS DisplayTableValueObject
