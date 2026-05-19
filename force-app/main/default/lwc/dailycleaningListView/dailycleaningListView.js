import { LightningElement, track } from 'lwc';
import getCases from '@salesforce/apex/CaseDmlController.getCases';
import updateCases from '@salesforce/apex/CaseDmlController.updateCases';

const columns = [
    {
        label: '',
        type: 'startCleaningBtnType',
        fieldName: 'Id',
    },
    {
        label: '',
        type: 'completeCleaningBtnType',
        fieldName: 'Id',
    },
    {
        label: 'ID',
        fieldName: 'Id',
    },
    {
        label: 'ケース番号',
        fieldName: 'CaseNumber',
    },
    {
        label: '件名',
        fieldName: 'Subject',
        editable: true,
    },
    {
        label: '',
        type: 'uploadFilesBtnType',
        fieldName: 'Id',
    },
    {
        label: '',
        type: 'showFilesBtnType',
        fieldName: 'Id',
    }
];

export default class DailycleaningListView extends LightningElement {
    @track columns = columns;
    @track data = [];
    draftValues = [];
    error;

    connectedCallback() {
        this.loadCases();
    }

    loadCases() {
        Promise.all([getCases(),])
            .then(result => {
                this.data = result[0];
            })
            .catch(error => {
                this.error = error;
                console.error(this.error);
            });
    }

    startCleaning(event) {
        const rowId = event.detail.rowId;
        console.log(rowId);
    }

    completeCleaning(event) {
        const rowId = event.detail.rowId;
        console.log(rowId);
    }

    uploadFiles(event) {
        const rowId = event.detail.rowId;
        console.log(rowId);
    }

    showFiles(event) {
        const rowId = event.detail.rowId;
        console.log(rowId);
    }

    async handleSave(event) {
        const updateData = event.detail.draftValues;
        try {
            console.log(updateData);
            await updateCases({ cases: updateData });
            await this.loadCases();
            this.draftValues = [];
        } catch (error) {
            console.error(this.error);
        }
    }

    handleCancel() {
        this.draftValues = [];
    }
}