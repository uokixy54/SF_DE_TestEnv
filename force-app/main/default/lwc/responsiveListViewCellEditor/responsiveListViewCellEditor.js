import { LightningElement, api } from 'lwc';

export default class ResponsiveListViewCellEditor extends LightningElement {
    @api recordId;
    @api field;
    @api value;
    @api showLabel = false;

    get fieldType() {
        return this.field?.type || 'text';
    }

    get fieldLabel() {
        return this.showLabel ? this.field?.label : '';
    }

    // タイプ判定
    get isTextType() {
        return ['text', 'string', 'id', 'phone', 'email', 'url'].includes(this.fieldType);
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

    get isPhoneType() {
        return this.fieldType === 'phone';
    }

    get isEmailType() {
        return this.fieldType === 'email';
    }

    get isUrlType() {
        return this.fieldType === 'url';
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

    get isReferenceType() {
        return this.fieldType === 'reference';
    }

    // 数値のステップ値
    get numberStep() {
        if (this.field?.scale > 0) {
            return Math.pow(10, -this.field.scale);
        }
        return 1;
    }

    // ピックリストオプション
    get picklistOptions() {
        if (!this.field?.picklistValues) return [];
        
        const options = this.field.picklistValues.map(pv => ({
            label: pv.label,
            value: pv.value
        }));
        
        // 必須でない場合は「--なし--」オプションを追加
        if (!this.field.required) {
            options.unshift({ label: '--なし--', value: '' });
        }
        
        return options;
    }

    // マルチピックリストの値（配列形式）
    get multiPicklistValues() {
        if (!this.value) return [];
        return this.value.split(';').filter(v => v);
    }

    // 値変更ハンドラ
    handleChange(event) {
        let newValue = event.target.value;
        const fieldName = this.field.fieldApiName;
        
        // Boolean型の特別処理
        if (this.isBooleanType) {
            newValue = event.target.checked;
        }
        
        // 数値型の検証
        if (this.isNumberType || this.isCurrencyType || this.isPercentType) {
            if (newValue !== '' && newValue !== null) {
                newValue = parseFloat(newValue);
                if (isNaN(newValue)) {
                    this.showError('無効な数値です');
                    return;
                }
            }
        }
        
        // 値変更イベントをディスパッチ
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                recordId: this.recordId,
                fieldName: fieldName,
                value: newValue
            }
        }));
    }

    // マルチピックリスト変更ハンドラ
    handleMultiPicklistChange(event) {
        const selectedValues = event.detail.value;
        const newValue = selectedValues.join(';');
        
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                recordId: this.recordId,
                fieldName: this.field.fieldApiName,
                value: newValue
            }
        }));
    }

    // エラー表示
    showError(message) {
        // 親コンポーネントにエラーを通知
        this.dispatchEvent(new CustomEvent('error', {
            detail: { message }
        }));
    }
}