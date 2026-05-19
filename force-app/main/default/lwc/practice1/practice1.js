import { LightningElement, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_STAGE from "@salesforce/schema/Opportunity.StageName"

export default class Practice1 extends LightningElement {
    /**
     * フィールド定義
     */
    opportunityPhases;
    error;
    selectValue = 'None';

    /**
     * ワイヤアダプタ定義
     */
    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: OPPORTUNITY_STAGE })
    getOpportunityPhase({ error, data }) {
        if (data) {
            this.opportunityPhases = [
                { label: "--None--", value: "None" },
                ...data.values
            ];
            this.error = undefined;
        } else if (error) {
            this.opportunityPhase = undefined;
            this.error = error;
        }
    }

    /**
     * イベントハンドラ定義
     */
    handleChange(event) {
        this.selectValue = event.target.value;
    }

}