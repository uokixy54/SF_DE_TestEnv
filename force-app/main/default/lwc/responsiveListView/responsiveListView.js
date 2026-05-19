import { LightningElement, api, track, wire } from 'lwc';
import getListViewData from '@salesforce/apex/ResponsiveListViewController.getListViewData';
import updateRecords from '@salesforce/apex/ResponsiveListViewController.updateRecords';
import bulkUpdateRecords from '@salesforce/apex/ResponsiveListViewController.bulkUpdateRecords';
import getObjectInfo from '@salesforce/apex/ResponsiveListViewController.getObjectInfo';
import searchRecords from '@salesforce/apex/ResponsiveListViewController.searchRecords';

export default class ResponsiveListView extends LightningElement {
    // 公開プロパティ
    @api objectApiName;
    @api fieldsToDisplay;
    @api whereClause;
    @api orderBy;
    @api pageSize = 20;
    @api enableInlineEdit;
    @api enableBulkEdit;
    @api enableSearch;
    @api enableSort;
    @api mobileDisplayFields;
    @api mobileLayoutType = 'card';

    // 内部状態
    @track records = [];
    @track displayRecords = [];
    @track columns = [];
    @track mobileColumns = [];
    @track selectedRecords = new Set();
    @track isLoading = true;
    @track error;
    @track successMessage;
    @track warningMessage;
    @track totalRecords = 0;
    @track currentPage = 1;
    @track totalPages = 1;
    @track sortField;
    @track sortDirection = 'ASC';
    @track searchTerm = '';
    @track searchTimeoutId;
    @track editedRecords = {};
    @track isBulkEditMode = false;
    @track bulkEditField;
    @track bulkEditValue;
    @track bulkEditPicklistOptions = [];
    
    // オブジェクト情報
    objectLabel = '';
    objectLabelPlural = '';
    isCreateable = false;
    isUpdateable = false;
    isDeletable = false;

    // レスポンシブ対応
    @track isMobile = false;
    resizeObserver;

    // ライフサイクルフック
    connectedCallback() {
        this.setupResponsiveObserver();
        this.initializeDefaults();
        this.loadData();
    }

    // デフォルト値の初期化
    initializeDefaults() {
        // プロパティが未設定の場合のデフォルト値
        if (this.pageSize === undefined || this.pageSize === null) {
            this.pageSize = 20;
        }
        
        // ページサイズのバリデーション（5〜100の範囲）
        if (this.pageSize < 5) {
            this.pageSize = 5;
        } else if (this.pageSize > 100) {
            this.pageSize = 100;
        }
        
        if (this.mobileLayoutType === undefined || this.mobileLayoutType === null) {
            this.mobileLayoutType = 'card';
        }
        
        // mobileLayoutTypeのバリデーション
        if (!['card', 'tile'].includes(this.mobileLayoutType)) {
            this.mobileLayoutType = 'card';
        }
    }

    disconnectedCallback() {
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
        }
    }

    // レスポンシブ設定
    setupResponsiveObserver() {
        this.checkMobileView();
        this.resizeObserver = new ResizeObserver(() => {
            this.checkMobileView();
        });
        this.resizeObserver.observe(document.body);
    }

    checkMobileView() {
        this.isMobile = window.innerWidth < 768;
    }

    // データ読み込み
    async loadData() {
        try {
            this.isLoading = true;
            this.error = undefined;

            // オブジェクト情報取得
            if (this.objectApiName) {
                const objectInfo = await getObjectInfo({ objectApiName: this.objectApiName });
                this.objectLabel = objectInfo.label;
                this.objectLabelPlural = objectInfo.labelPlural;
                this.isCreateable = objectInfo.isCreateable;
                this.isUpdateable = objectInfo.isUpdateable;
                this.isDeletable = objectInfo.isDeletable;
            }

            // リストデータ取得
            const result = await getListViewData({
                objectApiName: this.objectApiName,
                fieldsToDisplay: this.fieldsToDisplay,
                whereClause: this.whereClause,
                orderBy: this.orderBy || this.buildOrderByClause(),
                pageSize: this.pageSize,
                pageNumber: this.currentPage
            });

            this.processListViewData(result);
        } catch (error) {
            this.error = error.body?.message || error.message || 'データの読み込みに失敗しました';
            console.error('Error loading data:', error);
        } finally {
            this.isLoading = false;
        }
    }

    processListViewData(result) {
        this.records = result.records || [];
        this.totalRecords = result.totalRecords || 0;
        this.totalPages = result.totalPages || 1;
        
        // カラム設定
        this.setupColumns(result.fieldMetadata || []);
        
        // 表示用レコードの準備
        this.prepareDisplayRecords();
    }

    setupColumns(fieldMetadata) {
        this.columns = fieldMetadata.map(field => ({
            ...field,
            cellClass: this.getCellClass(field.type),
            sortable: this.enableSortValue && field.sortable,
            sortIcon: this.getSortIcon(field.fieldApiName)
        }));

        // モバイル用カラム設定
        if (this.mobileDisplayFields) {
            const mobileFields = this.mobileDisplayFields.split(',').map(f => f.trim());
            this.mobileColumns = this.columns.filter(col => 
                mobileFields.includes(col.fieldApiName)
            );
        } else {
            // デフォルトでは最初の5フィールドを表示
            this.mobileColumns = this.columns.slice(0, 5);
        }
    }

    prepareDisplayRecords() {
        this.displayRecords = this.records.map(record => {
            const displayRecord = {
                ...record,
                selected: this.selectedRecords.has(record.Id),
                editMode: false,
                originalValues: { ...record },
                cells: [],
                editKey: `${record.Id}-edit`
            };
            
            // 各カラムのセル情報を準備
            displayRecord.cells = this.columns.map(column => ({
                fieldApiName: column.fieldApiName,
                value: this.getCellValue(record, column.fieldApiName),
                column: column
            }));
            
            return displayRecord;
        });
        
        // モバイル用のセル情報も準備
        this.displayRecords.forEach(record => {
            record.mobileCells = this.mobileColumns.map(column => ({
                fieldApiName: column.fieldApiName,
                value: this.getCellValue(record, column.fieldApiName),
                column: column
            }));
        });
    }
    
    getCellValue(record, fieldApiName) {
        if (fieldApiName.includes('.')) {
            // 関連項目の処理
            const parts = fieldApiName.split('.');
            let value = record;
            for (const part of parts) {
                if (value && value[part] !== undefined) {
                    value = value[part];
                } else {
                    return null;
                }
            }
            return value;
        }
        return record[fieldApiName];
    }

    getCellClass(fieldType) {
        switch (fieldType) {
            case 'currency':
            case 'double':
            case 'integer':
            case 'percent':
                return 'slds-text-align_right';
            case 'boolean':
            case 'date':
            case 'datetime':
                return 'slds-text-align_center';
            default:
                return '';
        }
    }

    getSortIcon(fieldApiName) {
        if (this.sortField === fieldApiName) {
            return this.sortDirection === 'ASC' ? 'utility:arrowup' : 'utility:arrowdown';
        }
        return 'utility:sort';
    }

    buildOrderByClause() {
        if (this.sortField) {
            return `${this.sortField} ${this.sortDirection}`;
        }
        return null;
    }

    // 検索処理
    handleSearch(event) {
        const searchTerm = event.target.value;
        
        // デバウンス処理
        clearTimeout(this.searchTimeoutId);
        
        this.searchTimeoutId = setTimeout(() => {
            this.searchTerm = searchTerm;
            if (searchTerm.length >= 2) {
                this.performSearch();
            } else if (searchTerm.length === 0) {
                this.loadData();
            }
        }, 300);
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    async performSearch() {
        try {
            this.isLoading = true;
            
            const results = await searchRecords({
                objectApiName: this.objectApiName,
                fieldsToDisplay: this.fieldsToDisplay,
                searchTerm: this.searchTerm,
                whereClause: this.whereClause,
                maxResults: 200
            });

            this.records = results.map(r => r.record);
            this.totalRecords = results.length;
            this.totalPages = 1;
            this.currentPage = 1;
            this.prepareDisplayRecords();

        } catch (error) {
            this.showMessage('検索に失敗しました', 'error');
            console.error('Search error:', error);
        } finally {
            this.isLoading = false;
        }
    }

    // ソート処理
    handleSort(event) {
        const fieldName = event.currentTarget.dataset.field;
        
        if (this.sortField === fieldName) {
            this.sortDirection = this.sortDirection === 'ASC' ? 'DESC' : 'ASC';
        } else {
            this.sortField = fieldName;
            this.sortDirection = 'ASC';
        }
        
        this.currentPage = 1;
        this.loadData();
    }

    // 選択処理
    handleSelectAll(event) {
        const isChecked = event.target.checked;
        
        this.displayRecords = this.displayRecords.map(record => ({
            ...record,
            selected: isChecked
        }));
        
        if (isChecked) {
            this.displayRecords.forEach(record => this.selectedRecords.add(record.Id));
        } else {
            this.selectedRecords.clear();
        }
    }

    handleRecordSelect(event) {
        const recordId = event.target.dataset.id;
        const isChecked = event.target.checked;
        
        const recordIndex = this.displayRecords.findIndex(r => r.Id === recordId);
        if (recordIndex !== -1) {
            this.displayRecords[recordIndex].selected = isChecked;
        }
        
        if (isChecked) {
            this.selectedRecords.add(recordId);
        } else {
            this.selectedRecords.delete(recordId);
        }
    }

    // インライン編集
    startInlineEdit(event) {
        const recordId = event.currentTarget.dataset.id;
        const fieldName = event.currentTarget.dataset.field;
        
        this.setRecordEditMode(recordId, true);
    }

    startMobileEdit(event) {
        const recordId = event.currentTarget.dataset.id;
        this.setRecordEditMode(recordId, true);
    }

    setRecordEditMode(recordId, editMode) {
        const recordIndex = this.displayRecords.findIndex(r => r.Id === recordId);
        if (recordIndex !== -1) {
            this.displayRecords[recordIndex].editMode = editMode;
            
            if (editMode) {
                this.editedRecords[recordId] = { ...this.displayRecords[recordIndex] };
            } else {
                delete this.editedRecords[recordId];
            }
        }
    }

    handleCellValueChange(event) {
        const { recordId, fieldName, value } = event.detail;
        
        if (this.editedRecords[recordId]) {
            this.editedRecords[recordId][fieldName] = value;
        }
    }

    async saveInlineEdit(event) {
        const recordId = event.currentTarget.dataset.id;
        
        try {
            const recordToUpdate = {
                Id: recordId,
                ...this.getChangedFields(recordId)
            };
            
            const result = await updateRecords({ records: [recordToUpdate] });
            
            if (result.success) {
                this.showMessage('レコードが更新されました', 'success');
                
                // レコードを更新
                const recordIndex = this.displayRecords.findIndex(r => r.Id === recordId);
                if (recordIndex !== -1) {
                    Object.assign(this.displayRecords[recordIndex], this.editedRecords[recordId]);
                    this.displayRecords[recordIndex].originalValues = { ...this.displayRecords[recordIndex] };
                }
                
                this.setRecordEditMode(recordId, false);
            } else {
                const errors = result.errorRecords?.[0]?.errors || ['更新に失敗しました'];
                this.showMessage(errors.join(', '), 'error');
            }
        } catch (error) {
            this.showMessage('更新に失敗しました', 'error');
            console.error('Save error:', error);
        }
    }

    cancelInlineEdit(event) {
        const recordId = event.currentTarget.dataset.id;
        
        // 元の値に戻す
        const recordIndex = this.displayRecords.findIndex(r => r.Id === recordId);
        if (recordIndex !== -1) {
            Object.assign(this.displayRecords[recordIndex], this.displayRecords[recordIndex].originalValues);
        }
        
        this.setRecordEditMode(recordId, false);
    }

    getChangedFields(recordId) {
        const original = this.displayRecords.find(r => r.Id === recordId)?.originalValues || {};
        const edited = this.editedRecords[recordId] || {};
        const changes = {};
        
        for (const field in edited) {
            if (edited[field] !== original[field] && field !== 'Id' && field !== 'selected' && field !== 'editMode' && field !== 'originalValues') {
                changes[field] = edited[field];
            }
        }
        
        return changes;
    }

    // 一括編集
    startBulkEdit() {
        this.isBulkEditMode = true;
        this.bulkEditField = null;
        this.bulkEditValue = null;
    }

    cancelBulkEdit() {
        this.isBulkEditMode = false;
        this.bulkEditField = null;
        this.bulkEditValue = null;
    }

    handleBulkEditFieldChange(event) {
        this.bulkEditField = event.detail.value;
        this.bulkEditValue = null;
        
        // ピックリストの場合は選択肢を設定
        const field = this.columns.find(col => col.fieldApiName === this.bulkEditField);
        if (field && field.picklistValues) {
            this.bulkEditPicklistOptions = field.picklistValues.map(pv => ({
                label: pv.label,
                value: pv.value
            }));
        }
    }

    handleBulkEditValueChange(event) {
        this.bulkEditValue = event.detail.value;
    }

    async applyBulkEdit() {
        if (!this.bulkEditField || this.bulkEditValue === null || this.bulkEditValue === undefined) {
            this.showMessage('項目と値を入力してください', 'error');
            return;
        }
        
        try {
            const recordIds = Array.from(this.selectedRecords);
            
            const result = await bulkUpdateRecords({
                recordIds: recordIds,
                objectApiName: this.objectApiName,
                fieldApiName: this.bulkEditField,
                fieldValue: this.bulkEditValue
            });
            
            if (result.success) {
                this.showMessage(`${result.successCount}件のレコードが更新されました`, 'success');
                this.cancelBulkEdit();
                this.selectedRecords.clear();
                this.loadData();
            } else {
                const errorMsg = result.errors?.join(', ') || '一括更新に失敗しました';
                this.showMessage(errorMsg, 'error');
            }
        } catch (error) {
            this.showMessage('一括更新に失敗しました', 'error');
            console.error('Bulk update error:', error);
        }
    }

    // ページネーション
    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadData();
        }
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadData();
        }
    }

    goToPage(event) {
        const pageNumber = parseInt(event.currentTarget.dataset.page, 10);
        if (pageNumber !== this.currentPage) {
            this.currentPage = pageNumber;
            this.loadData();
        }
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.currentPage = 1;
        this.loadData();
    }

    // ユーティリティ
    showMessage(message, variant) {
        // メッセージを一定時間表示した後にクリア
        if (variant === 'success') {
            this.successMessage = message;
            this.error = null;
            this.warningMessage = null;
        } else if (variant === 'warning') {
            this.warningMessage = message;
            this.error = null;
            this.successMessage = null;
        } else {
            this.error = message;
            this.successMessage = null;
            this.warningMessage = null;
        }
        
        // 5秒後にメッセージをクリア（エラーメッセージは除く）
        if (variant !== 'error') {
            setTimeout(() => {
                this.clearMessages();
            }, 5000);
        }
    }

    clearMessages() {
        this.successMessage = null;
        this.warningMessage = null;
        // エラーメッセージは手動でクリアするまで残す
    }

    // ゲッター
    get hasData() {
        return this.records.length > 0;
    }

    get enableInlineEditValue() {
        return this.enableInlineEdit !== false;
    }

    get enableBulkEditValue() {
        return this.enableBulkEdit !== false;
    }

    get enableSearchValue() {
        return this.enableSearch !== false;
    }

    get enableSortValue() {
        return this.enableSort !== false;
    }

    get hasSelectedRecords() {
        return this.selectedRecords.size > 0;
    }

    get selectedRecordCount() {
        return this.selectedRecords.size;
    }

    get allSelected() {
        return this.displayRecords.length > 0 && 
               this.displayRecords.every(record => record.selected);
    }

    get columnCount() {
        return this.columns ? this.columns.length + 1 : 1;
    }

    get editableFieldOptions() {
        return this.columns
            .filter(col => col.updateable)
            .map(col => ({
                label: col.label,
                value: col.fieldApiName
            }));
    }

    get showBulkEditInput() {
        return this.bulkEditField != null;
    }

    get isBulkEditPicklist() {
        const field = this.columns.find(col => col.fieldApiName === this.bulkEditField);
        return field && (field.type === 'picklist' || field.type === 'multipicklist');
    }

    get bulkEditInputType() {
        const field = this.columns.find(col => col.fieldApiName === this.bulkEditField);
        if (!field) return 'text';
        
        switch (field.type) {
            case 'boolean': return 'checkbox';
            case 'date': return 'date';
            case 'datetime': return 'datetime';
            case 'email': return 'email';
            case 'number':
            case 'currency':
            case 'percent':
            case 'double': return 'number';
            case 'phone': return 'tel';
            case 'url': return 'url';
            default: return 'text';
        }
    }

    get disableBulkEditApply() {
        return !this.bulkEditField || 
               this.bulkEditValue === null || 
               this.bulkEditValue === undefined ||
               this.bulkEditValue === '';
    }

    get showPagination() {
        return this.totalPages > 1;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get pageNumbers() {
        const pages = [];
        const maxVisiblePages = 5;
        let startPage = Math.max(1, this.currentPage - Math.floor(maxVisiblePages / 2));
        let endPage = Math.min(this.totalPages, startPage + maxVisiblePages - 1);
        
        if (endPage - startPage < maxVisiblePages - 1) {
            startPage = Math.max(1, endPage - maxVisiblePages + 1);
        }
        
        for (let i = startPage; i <= endPage; i++) {
            pages.push({
                number: i,
                variant: i === this.currentPage ? 'brand' : 'neutral'
            });
        }
        
        return pages;
    }

    get recordRangeText() {
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, this.totalRecords);
        return `${start} - ${end}`;
    }

    get pageSizeOptions() {
        return [
            { label: '10件', value: '10' },
            { label: '20件', value: '20' },
            { label: '50件', value: '50' },
            { label: '100件', value: '100' }
        ];
    }

    get mobileLayoutClass() {
        return this.mobileLayoutType === 'tile' ? 'mobile-tile-layout' : 'mobile-card-layout';
    }

    get mobileItemClass() {
        return this.mobileLayoutType === 'tile' ? 'mobile-tile-item' : 'mobile-card-item';
    }
}