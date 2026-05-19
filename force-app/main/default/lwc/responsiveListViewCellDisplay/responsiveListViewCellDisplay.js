import { LightningElement, api } from 'lwc';

export default class ResponsiveListViewCellDisplay extends LightningElement {
    @api field;
    @api value;

    get fieldType() {
        return this.field?.type || 'text';
    }

    get displayValue() {
        if (this.value === null || this.value === undefined) {
            return '';
        }
        
        // 参照項目の処理
        if (this.fieldType === 'reference' && typeof this.value === 'object') {
            // 関連項目から表示値を取得（Name項目を優先）
            return this.value.Name || this.value.Id || '';
        }
        
        return String(this.value);
    }

    // タイプ判定
    get isTextType() {
        return ['text', 'string', 'id'].includes(this.fieldType);
    }

    get isBooleanType() {
        return this.fieldType === 'boolean';
    }

    get isDateType() {
        return this.fieldType === 'date';
    }

    get isDateTimeType() {
        return this.fieldType === 'datetime';
    }

    get isTimeType() {
        return this.fieldType === 'time';
    }

    get isNumberType() {
        return ['double', 'integer', 'long'].includes(this.fieldType);
    }

    get isCurrencyType() {
        return this.fieldType === 'currency';
    }

    get isPercentType() {
        return this.fieldType === 'percent';
    }

    get isPhoneType() {
        return this.fieldType === 'phone';
    }

    get isEmailType() {
        return this.fieldType === 'email';
    }

    get isUrlType() {
        return this.fieldType === 'url';
    }

    get isReferenceType() {
        return this.fieldType === 'reference';
    }

    get isPicklistType() {
        return this.fieldType === 'picklist';
    }

    get isMultiPicklistType() {
        return this.fieldType === 'multipicklist';
    }

    get isTextAreaType() {
        return this.fieldType === 'textarea';
    }

    // Boolean表示
    get booleanIcon() {
        return this.value ? 'utility:check' : 'utility:close';
    }

    get booleanVariant() {
        return this.value ? 'success' : '';
    }

    get booleanLabel() {
        return this.value ? 'はい' : 'いいえ';
    }

    // パーセント表示
    get percentValue() {
        // Salesforceのパーセント項目は100倍された値で保存されているため、100で割る
        return this.value / 100;
    }

    // URL表示
    get urlLabel() {
        if (!this.value) return '';
        
        try {
            const url = new URL(this.value);
            return url.hostname;
        } catch (e) {
            return this.value;
        }
    }

    // 参照項目のURL
    get referenceUrl() {
        if (!this.value || typeof this.value !== 'object') return '#';
        
        const recordId = this.value.Id;
        if (!recordId) return '#';
        
        // Lightning Experience/Communities向けのURL
        return `/lightning/r/${recordId}/view`;
    }

    // マルチピックリストの値
    get multiPicklistValues() {
        if (!this.value) return [];
        return this.value.split(';').filter(v => v);
    }

    // テキストエリアの表示値（改行を考慮）
    get textAreaDisplayValue() {
        if (!this.value) return '';
        
        // 最初の3行まで表示
        const lines = this.value.split('\n');
        if (lines.length <= 3) {
            return this.value;
        }
        
        return lines.slice(0, 3).join('\n') + '...';
    }
}