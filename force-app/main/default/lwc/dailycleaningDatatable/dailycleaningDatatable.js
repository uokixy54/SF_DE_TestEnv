import LightningDatatable from 'lightning/datatable';
import startCleaningBtnTemplate from './startCleaningBtnTemplate.html';
import completeCleaningBtnTemplate from './completeCleaningBtnTemplate.html';
import uploadFilesBtnTemplate from './uploadFilesBtnTemplate.html';
import showFilesBtnTemplate from './showFilesBtnTemplate.html';


export default class DailycleaningDatatable extends LightningDatatable {
    static customTypes = {
        startCleaningBtnType: {
            template: startCleaningBtnTemplate
        },
        completeCleaningBtnType: {
            template: completeCleaningBtnTemplate
        },
        uploadFilesBtnType: {
            template: uploadFilesBtnTemplate
        },
        showFilesBtnType: {
            template: showFilesBtnTemplate
        }
    }
}