import { LightningElement, wire } from 'lwc';
import getCases from '@salesforce/apex/CaseDmlController.getCases';

const COLUMNS = [
    { label: 'CaseNumber', fieldName: 'CaseNumber' },
    { label: 'Subject', fieldName: 'Subject' },
];

export default class CustomDatatableDemo extends LightningElement {
    cases;
    columns = COLUMNS;

    @wire(getCases)
    wiredCases({ error, data }) {
        if (data) {
            this.cases = data;
        } else if (error) {
            console.error(error);
        }
    }
}