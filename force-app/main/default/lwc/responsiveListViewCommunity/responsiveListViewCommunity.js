import { LightningElement } from 'lwc';

export default class ResponsiveListViewCommunity extends LightningElement {
    // エクスペリエンスクラウド用の設定
    // これらの値は開発者がコードで直接設定する必要があります
    
    // 必須設定 - 使用するオブジェクトとフィールドを指定
    objectApiName = 'Account'; // 例: 'Account', 'Contact', 'CustomObject__c'
    fieldsToDisplay = 'Name,Type,Industry,Phone'; // 表示したいフィールドをカンマ区切りで指定
    
    // オプション設定
    whereClause = ''; // 例: "Type = 'Customer'"
    orderBy = 'Name ASC'; // 例: 'Name ASC', 'CreatedDate DESC'
    pageSize = 20;
    
    // 機能の有効/無効
    enableInlineEdit = true;
    enableBulkEdit = true;
    enableSearch = true;
    enableSort = true;
    
    // モバイル表示設定
    mobileDisplayFields = ''; // 空の場合は最初の5フィールドを表示
    mobileLayoutType = 'card'; // 'card' または 'tile'
    
    // 使用例:
    // Account オブジェクトを表示する場合
    // objectApiName = 'Account';
    // fieldsToDisplay = 'Name,Type,Industry,Phone,Website';
    // whereClause = 'Type != null';
    // orderBy = 'Name ASC';
    
    // Contact オブジェクトを表示する場合
    // objectApiName = 'Contact';
    // fieldsToDisplay = 'Name,Email,Phone,Account.Name';
    // whereClause = 'Email != null';
    // orderBy = 'LastName ASC, FirstName ASC';
    
    // カスタムオブジェクトを表示する場合
    // objectApiName = 'CustomObject__c';
    // fieldsToDisplay = 'Name,CustomField1__c,CustomField2__c';
    // whereClause = 'CustomField1__c != null';
    // orderBy = 'CreatedDate DESC';
}