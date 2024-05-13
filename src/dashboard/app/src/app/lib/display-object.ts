import {DisplayTableValueObject} from "./display-table-value-object";

export class DisplayObject {

    displayType: string;
    numberTableFields: number;
    tableFields: DisplayTableValueObject[];
    colors: string[];
    displayData: any[];


    constructor(jsonObject = {}) {
        this.displayType = 'choropleth';
        this.numberTableFields = 1;
        this.tableFields = [];
        this.displayData = [];

        for (const field in jsonObject) {
            if (field === 'displayType') {
                this.displayType = jsonObject[field];
                switch(jsonObject[field]) {
                    case 'bivariate':
                        this.numberTableFields = 2;
                        break;
                    default:
                        this.numberTableFields = 1;
                        break;
                }
            } else if (field === 'tableFields') {
                // console.log('tableFields: ', jsonObject[field]);
                let tableFieldsJson = jsonObject[field];
                tableFieldsJson.forEach( (tableField, index) => {
                    this.tableFields.push(new DisplayTableValueObject(tableField, index));
                });
            } else {
                this[field] = jsonObject[field];
            }
        }

        this.checkTableFields();


    } // END CONSTRUCTOR


    checkTableFields() {
        let tmpTableFields = [];
        for (let i = 0; i < this.numberTableFields; i++) {
            if (typeof this.tableFields[i] !== 'undefined') {
                tmpTableFields.push(this.tableFields[i]);
            } else {
                tmpTableFields.push(new DisplayTableValueObject());
            }
            switch(this.displayType) {
                case 'bivariate':
                    if (i === 0) {
                        tmpTableFields[i].tableFunction = 'Predictor';
                    } else if (i === 1) {
                        tmpTableFields[i].tableFunction = 'Outcome';
                    } else {
                        tmpTableFields[i].tableFunction = '?';
                    }
                    break;

                default:
                    tmpTableFields[i].tableFunction = 'Value';
                    break;
            }
        }
        this.tableFields = tmpTableFields;
    } // END FUNCTION checkTableFields




    logConsole() {
        console.log('displayObject: ', this);
    } // END FUNCTION logConsole;





} // END CLASS DisplayObject
