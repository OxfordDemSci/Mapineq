export class DisplayTableValueObject {
    tableId: number;
    tableName: string;
    tableDescr: string;
    tableFunction: string;
    tableYear: string;
    tableRegionLevel: string;
    tableColumnValues: any;
    tableSelectionComplete: boolean;

    constructor(jsonObject = {}, index = 0) {
        this.tableId = index;
        this.tableName = '';
        this.tableDescr = '';
        this.tableFunction = '';
        this.tableYear = '-1';
        this.tableRegionLevel = '-1';
        this.tableColumnValues = {};
        this.tableSelectionComplete = false;

        for (const field in jsonObject) {
            if(Object.getOwnPropertyNames(this).includes(field)) {
                this[field] = jsonObject[field];
            } else {
                console.log('Non existing property: ', field);
            }
        }

        this.checkSelectionComplete();
    } // END constructor

    checkSelectionComplete() {
        // console.log('checkSelectionComplete()', this);
        let selectionComplete = true;
        if (this.tableRegionLevel === '-1') {
            selectionComplete = false;
        }
        if (this.tableName === '') {
            selectionComplete = false;
        }
        if (this.tableDescr === '') {
            selectionComplete = false;
        }
        if (this.tableYear === '-1') {
            selectionComplete = false;
        }
        if (Object.values(this.tableColumnValues).length === 0) {
            selectionComplete = false;
        } else {
            Object.values(this.tableColumnValues).forEach( columnValue => {
                if (columnValue === '') {
                    selectionComplete = false;
                }
            });
        }
        this.tableSelectionComplete = selectionComplete;
    } // END FUNCTION checkSelectionComplete();

} // END CLASS DisplayTableValueObject
