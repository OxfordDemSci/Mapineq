import {DisplayTableValueObject} from "./display-table-value-object";

export class DisplayObject {

    // private objectHttpClient: HttpClient;
    // private objectFeatureService: FeatureService

    formType: string;
    numberTableFields: number;
    tableFields: DisplayTableValueObject[];
    colors: string[];
    displayType: string;
    displayTableId: number;
    displayData: any[];


    constructor(jsonObject = {}) {
        this.formType = 'choropleth';
        this.numberTableFields = 1;
        this.tableFields = [];
        this.displayType = '';
        this.displayTableId = -1;
        this.displayData = [];

        //this.objectHttpClient = new HttpClient()
        // this.objectFeatureService = new FeatureService()
        // this.objectFeatureService = new FeatureService(objectHttpClient);

        for (const field in jsonObject) {
            if (field === 'formType') {
                this.formType = jsonObject[field];
                switch(jsonObject[field]) {
                    case 'bivariate':
                        this.numberTableFields = 2;
                        this.displayType = 'bivariate';
                        break;
                    default:
                        this.numberTableFields = 1;
                        this.displayType = 'choropleth'
                        break;
                }
            } else if (field === 'tableFields') {
                console.log('tableFields: ', jsonObject[field]);
                let tableFieldsJson = jsonObject[field];
                //console.log('CALLED before tableFieldsJson.forEach(), tableFieldsJson', tableFieldsJson);
                tableFieldsJson.forEach( (tableField, index) => {
                    //console.log('CALLED in tableFieldsJson.forEach(), index / tableField', index, tableField);
                    this.tableFields.push(new DisplayTableValueObject(tableField, index));
                });
            } else {
                if(Object.getOwnPropertyNames(this).includes(field)) {
                    this[field] = jsonObject[field];
                } else {
                    console.log('Non existing property: ', field);
                }
            }
        }

        this.checkTableFields();


    } // END CONSTRUCTOR


    checkTableFields() {
        // console.log('CALLED checkTableFields()', this.numberTableFields);
        let tmpTableFields = [];
        for (let i = 0; i < this.numberTableFields; i++) {
            if (typeof this.tableFields[i] !== 'undefined') {
                tmpTableFields.push(this.tableFields[i]);
            } else {
                tmpTableFields.push(new DisplayTableValueObject());
            }
            switch(this.formType) {
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
