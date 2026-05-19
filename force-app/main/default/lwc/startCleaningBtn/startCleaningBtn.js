import { LightningElement, api } from 'lwc';

export default class StartCleaningBtn extends LightningElement {
    @api rowId;

    handleClick() {
        const event = new CustomEvent('startcleaning', {
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