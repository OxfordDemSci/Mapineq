export class DisplayTableValueObject {
    tableId: number;
    tableName: string;
    tableDescr: string;
    tableShortDescr: string;
    tableFunction: string;
    tableYear: string;
    tableRegionLevel: string;
    tableColumnValues: any;
    tableSelectionComplete: boolean;
    tableShowOnlyThisTable: boolean;
    Selections: any;

    lastTableName: string;
    lastTableYear: string;
    lastSelections: any;

    constructor(jsonObject = {}, index = 0) {
        // console.log('DisplayTableValueObject CONSTRUCTOR, index/jsonObject:', index, jsonObject);
        this.tableId = index;
        this.tableName = '';
        this.tableDescr = '';
        this.tableShortDescr = '';
        this.tableFunction = '';
        this.tableYear = '-1';
        this.tableRegionLevel = '-1';
        this.tableColumnValues = {};
        this.tableSelectionComplete = false;
        this.tableShowOnlyThisTable = false;
        this.Selections = {};

        this.lastTableName = '';
        this.lastTableYear = '';
        this.lastSelections = {};

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
        this.tableSelectionComplete = false;

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
