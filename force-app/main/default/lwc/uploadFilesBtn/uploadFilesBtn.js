import { LightningElement, api } from 'lwc';

export default class UploadFilesBtn extends LightningElement {
    @api rowId;

    handleClick() {
        const event = new CustomEvent('uploadfiles', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                rowId: this.rowId,
            },
        });
        this.dispatchEvent(event);
    }
}