public with sharing class ResponsiveListViewController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getListViewData(
        String objectApiName, 
        String fieldsToDisplay, 
        String whereClause, 
        String orderBy,
        Integer pageSize,
        Integer pageNumber
    ) {
        try {
            ResponsiveListViewHelper helper = new ResponsiveListViewHelper();
            
            // パラメータ検証
            helper.validateParameters(objectApiName, fieldsToDisplay);
            
            // オブジェクトとフィールドのアクセス権限チェック
            if (!helper.hasObjectAccess(objectApiName)) {
                throw new AuraHandledException('Insufficient privileges to access object: ' + objectApiName);
            }
            
            List<String> fields = helper.parseFields(fieldsToDisplay);
            helper.checkFieldAccess(objectApiName, fields);
            
            // SOQLクエリ構築
            String query = helper.buildQuery(objectApiName, fields, whereClause, orderBy, pageSize, pageNumber);
            
            // データ取得
            List<SObject> records = Database.query(query);
            
            // 総レコード数取得
            String countQuery = helper.buildCountQuery(objectApiName, whereClause);
            Integer totalRecords = Database.countQuery(countQuery);
            
            // フィールドメタデータ取得
            List<Map<String, Object>> fieldMetadata = helper.getFieldMetadata(objectApiName, fields);
            
            // レスポンス構築
            Map<String, Object> response = new Map<String, Object>{
                'records' => records,
                'totalRecords' => totalRecords,
                'pageSize' => pageSize,
                'pageNumber' => pageNumber,
                'totalPages' => Math.ceil((Decimal)totalRecords / pageSize).intValue(),
                'fieldMetadata' => fieldMetadata
            };
            
            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving list view data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> updateRecords(List<SObject> records) {
        try {
            ResponsiveListViewHelper helper = new ResponsiveListViewHelper();
            
            if (records == null || records.isEmpty()) {
                throw new AuraHandledException('No records to update');
            }
            
            // レコードタイプ取得
            String objectApiName = records[0].getSObjectType().getDescribe().getName();
            
            // 更新権限チェック
            if (!helper.hasUpdateAccess(objectApiName)) {
                throw new AuraHandledException('Insufficient privileges to update ' + objectApiName);
            }
            
            // 各レコードのフィールドレベルセキュリティチェック
            for (SObject record : records) {
                helper.checkFieldUpdateAccess(record);
            }
            
            // 部分更新のためのセーブポイント設定
            Savepoint sp = Database.setSavepoint();
            
            try {
                // レコード更新
                Database.SaveResult[] results = Database.update(records, false);
                
                // 結果処理
                List<Map<String, Object>> successRecords = new List<Map<String, Object>>();
                List<Map<String, Object>> errorRecords = new List<Map<String, Object>>();
                
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (result.isSuccess()) {
                        successRecords.add(new Map<String, Object>{
                            'id' => result.getId(),
                            'record' => records[i]
                        });
                    } else {
                        List<String> errors = new List<String>();
                        for (Database.Error error : result.getErrors()) {
                            errors.add(error.getMessage());
                        }
                        errorRecords.add(new Map<String, Object>{
                            'record' => records[i],
                            'errors' => errors
                        });
                    }
                }
                
                // エラーがある場合の処理
                if (!errorRecords.isEmpty() && successRecords.isEmpty()) {
                    Database.rollback(sp);
                    throw new AuraHandledException('All records failed to update');
                }
                
                return new Map<String, Object>{
                    'success' => true,
                    'successCount' => successRecords.size(),
                    'errorCount' => errorRecords.size(),
                    'successRecords' => successRecords,
                    'errorRecords' => errorRecords
                };
                
            } catch (Exception e) {
                Database.rollback(sp);
                throw e;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> bulkUpdateRecords(
        List<String> recordIds, 
        String objectApiName, 
        String fieldApiName, 
        Object fieldValue
    ) {
        try {
            ResponsiveListViewHelper helper = new ResponsiveListViewHelper();
            
            // パラメータ検証
            if (recordIds == null || recordIds.isEmpty()) {
                throw new AuraHandledException('No records selected for bulk update');
            }
            
            if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
                throw new AuraHandledException('Invalid parameters for bulk update');
            }
            
            // オブジェクトとフィールドのアクセス権限チェック
            if (!helper.hasUpdateAccess(objectApiName)) {
                throw new AuraHandledException('Insufficient privileges to update ' + objectApiName);
            }
            
            if (!helper.hasFieldUpdateAccess(objectApiName, fieldApiName)) {
                throw new AuraHandledException('Insufficient privileges to update field: ' + fieldApiName);
            }
            
            // レコード取得とロック
            String query = 'SELECT Id FROM ' + objectApiName + ' WHERE Id IN :recordIds FOR UPDATE';
            List<SObject> records = Database.query(query);
            
            // フィールド値設定
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeFieldResult fieldDescribe = targetType.getDescribe().fields.getMap().get(fieldApiName).getDescribe();
            
            for (SObject record : records) {
                record.put(fieldApiName, helper.convertFieldValue(fieldValue, fieldDescribe));
            }
            
            // 一括更新実行
            Savepoint sp = Database.setSavepoint();
            
            try {
                Database.SaveResult[] results = Database.update(records, false);
                
                // 結果処理
                Integer successCount = 0;
                List<String> errorMessages = new List<String>();
                
                for (Database.SaveResult result : results) {
                    if (result.isSuccess()) {
                        successCount++;
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            errorMessages.add(error.getMessage());
                        }
                    }
                }
                
                if (successCount == 0) {
                    Database.rollback(sp);
                    throw new AuraHandledException('Bulk update failed: ' + String.join(errorMessages, ', '));
                }
                
                return new Map<String, Object>{
                    'success' => true,
                    'successCount' => successCount,
                    'totalCount' => records.size(),
                    'errors' => errorMessages
                };
                
            } catch (Exception e) {
                Database.rollback(sp);
                throw e;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error in bulk update: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getObjectInfo(String objectApiName) {
        try {
            ResponsiveListViewHelper helper = new ResponsiveListViewHelper();
            
            if (!helper.hasObjectAccess(objectApiName)) {
                throw new AuraHandledException('Insufficient privileges to access object: ' + objectApiName);
            }
            
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            
            Map<String, Object> objectInfo = new Map<String, Object>{
                'label' => objectDescribe.getLabel(),
                'labelPlural' => objectDescribe.getLabelPlural(),
                'apiName' => objectDescribe.getName(),
                'isCreateable' => objectDescribe.isCreateable(),
                'isUpdateable' => objectDescribe.isUpdateable(),
                'isDeletable' => objectDescribe.isDeletable(),
                'isSearchable' => objectDescribe.isSearchable(),
                'isCustom' => objectDescribe.isCustom()
            };
            
            return objectInfo;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting object info: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> searchRecords(
        String objectApiName, 
        String fieldsToDisplay, 
        String searchTerm,
        String whereClause,
        Integer maxResults
    ) {
        try {
            ResponsiveListViewHelper helper = new ResponsiveListViewHelper();
            
            // パラメータ検証
            if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
                return new List<Map<String, Object>>();
            }
            
            helper.validateParameters(objectApiName, fieldsToDisplay);
            
            // セキュリティチェック
            if (!helper.hasObjectAccess(objectApiName)) {
                throw new AuraHandledException('Insufficient privileges to access object: ' + objectApiName);
            }
            
            List<String> fields = helper.parseFields(fieldsToDisplay);
            helper.checkFieldAccess(objectApiName, fields);
            
            // SOSL検索実行
            String searchQuery = helper.buildSearchQuery(objectApiName, fields, searchTerm, whereClause, maxResults);
            List<List<SObject>> searchResults = Search.query(searchQuery);
            
            // 結果フォーマット
            List<Map<String, Object>> formattedResults = new List<Map<String, Object>>();
            if (!searchResults.isEmpty()) {
                for (SObject record : searchResults[0]) {
                    Map<String, Object> recordMap = new Map<String, Object>{
                        'record' => record,
                        'id' => record.Id
                    };
                    formattedResults.add(recordMap);
                }
            }
            
            return formattedResults;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error searching records: ' + e.getMessage());
        }
    }
}