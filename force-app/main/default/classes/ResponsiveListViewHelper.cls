public with sharing class ResponsiveListViewHelper {
    
    // パラメータ検証
    public void validateParameters(String objectApiName, String fieldsToDisplay) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API name is required');
        }
        
        if (String.isBlank(fieldsToDisplay)) {
            throw new AuraHandledException('Fields to display are required');
        }
        
        // オブジェクトが存在するか確認
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType == null) {
            throw new AuraHandledException('Invalid object API name: ' + objectApiName);
        }
    }
    
    // オブジェクトアクセス権限チェック
    public Boolean hasObjectAccess(String objectApiName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        return objectType != null && objectType.getDescribe().isAccessible();
    }
    
    // オブジェクト更新権限チェック
    public Boolean hasUpdateAccess(String objectApiName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        return objectType != null && objectType.getDescribe().isUpdateable();
    }
    
    // フィールド文字列をリストに変換
    public List<String> parseFields(String fieldsToDisplay) {
        List<String> fields = new List<String>();
        
        for (String field : fieldsToDisplay.split(',')) {
            String trimmedField = field.trim();
            if (!String.isBlank(trimmedField)) {
                fields.add(trimmedField);
            }
        }
        
        // Idフィールドを必ず含める
        if (!fields.contains('Id')) {
            fields.add('Id');
        }
        
        return fields;
    }
    
    // フィールドアクセス権限チェック
    public void checkFieldAccess(String objectApiName, List<String> fields) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        
        for (String field : fields) {
            // 関連項目の処理
            if (field.contains('.')) {
                String[] parts = field.split('\\.', 2);
                String relationshipField = parts[0];
                
                // リレーションシップフィールドの存在確認
                if (!fieldMap.containsKey(relationshipField) && !fieldMap.containsKey(relationshipField + 'Id')) {
                    throw new AuraHandledException('Invalid field: ' + field);
                }
                continue;
            }
            
            // 通常フィールドのアクセス権限チェック
            Schema.SObjectField fieldToken = fieldMap.get(field);
            if (fieldToken == null) {
                throw new AuraHandledException('Invalid field: ' + field);
            }
            
            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
            if (!fieldDescribe.isAccessible()) {
                throw new AuraHandledException('Insufficient privileges to access field: ' + field);
            }
        }
    }
    
    // フィールド更新権限チェック
    public Boolean hasFieldUpdateAccess(String objectApiName, String fieldApiName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        
        Schema.SObjectField fieldToken = fieldMap.get(fieldApiName);
        if (fieldToken == null) {
            return false;
        }
        
        return fieldToken.getDescribe().isUpdateable();
    }
    
    // レコードのフィールドレベルセキュリティチェック
    public void checkFieldUpdateAccess(SObject record) {
        Schema.DescribeSObjectResult objectDescribe = record.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        
        Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();
        
        for (String fieldName : populatedFields.keySet()) {
            // システムフィールドはスキップ
            if (fieldName == 'Id' || fieldName == 'CreatedDate' || fieldName == 'LastModifiedDate') {
                continue;
            }
            
            Schema.SObjectField fieldToken = fieldMap.get(fieldName);
            if (fieldToken != null) {
                Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                if (!fieldDescribe.isUpdateable()) {
                    throw new AuraHandledException('Cannot update field: ' + fieldName);
                }
            }
        }
    }
    
    // SOQLクエリ構築
    public String buildQuery(String objectApiName, List<String> fields, String whereClause, String orderBy, Integer pageSize, Integer pageNumber) {
        // SELECT句構築
        String query = 'SELECT ' + String.escapeSingleQuotes(String.join(fields, ', '));
        
        // FROM句
        query += ' FROM ' + String.escapeSingleQuotes(objectApiName);
        
        // WHERE句（共有セット対応）
        List<String> conditions = new List<String>();
        
        // ユーザー指定のWHERE条件
        if (!String.isBlank(whereClause)) {
            conditions.add('(' + whereClause + ')');
        }
        
        // 共有セット条件の自動追加（外部ユーザーの場合）
        if (UserInfo.getUserType() == 'PowerPartner' || UserInfo.getUserType() == 'CSPLitePortal' || UserInfo.getUserType() == 'CustomerSuccess' || UserInfo.getUserType() == 'PowerCustomerSuccess') {
            // 共有セットは自動的に適用されるため、追加条件は不要
        }
        
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        // WITH SECURITY_ENFORCED
        query += ' WITH SECURITY_ENFORCED';
        
        // ORDER BY句
        if (!String.isBlank(orderBy)) {
            query += ' ORDER BY ' + String.escapeSingleQuotes(orderBy);
        } else {
            query += ' ORDER BY CreatedDate DESC';
        }
        
        // LIMIT/OFFSET句（ページング）
        if (pageSize != null && pageSize > 0) {
            query += ' LIMIT ' + pageSize;
            
            if (pageNumber != null && pageNumber > 0) {
                Integer offset = (pageNumber - 1) * pageSize;
                query += ' OFFSET ' + offset;
            }
        }
        
        return query;
    }
    
    // カウントクエリ構築
    public String buildCountQuery(String objectApiName, String whereClause) {
        String query = 'SELECT COUNT() FROM ' + String.escapeSingleQuotes(objectApiName);
        
        if (!String.isBlank(whereClause)) {
            query += ' WHERE ' + whereClause;
        }
        
        query += ' WITH SECURITY_ENFORCED';
        
        return query;
    }
    
    // フィールドメタデータ取得
    public List<Map<String, Object>> getFieldMetadata(String objectApiName, List<String> fields) {
        List<Map<String, Object>> fieldMetadata = new List<Map<String, Object>>();
        
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        
        for (String field : fields) {
            // 関連項目の処理
            if (field.contains('.')) {
                Map<String, Object> metadata = new Map<String, Object>{
                    'fieldApiName' => field,
                    'label' => field,
                    'type' => 'reference',
                    'updateable' => false,
                    'required' => false,
                    'sortable' => true
                };
                fieldMetadata.add(metadata);
                continue;
            }
            
            Schema.SObjectField fieldToken = fieldMap.get(field);
            if (fieldToken != null) {
                Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                
                Map<String, Object> metadata = new Map<String, Object>{
                    'fieldApiName' => fieldDescribe.getName(),
                    'label' => fieldDescribe.getLabel(),
                    'type' => fieldDescribe.getType().name().toLowerCase(),
                    'updateable' => fieldDescribe.isUpdateable(),
                    'required' => !fieldDescribe.isNillable() && fieldDescribe.isUpdateable(),
                    'sortable' => fieldDescribe.isSortable(),
                    'length' => fieldDescribe.getLength(),
                    'precision' => fieldDescribe.getPrecision(),
                    'scale' => fieldDescribe.getScale()
                };
                
                // ピックリストの場合は選択肢も含める
                if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    List<Map<String, String>> picklistValues = new List<Map<String, String>>();
                    for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                        if (entry.isActive()) {
                            picklistValues.add(new Map<String, String>{
                                'label' => entry.getLabel(),
                                'value' => entry.getValue()
                            });
                        }
                    }
                    metadata.put('picklistValues', picklistValues);
                }
                
                // 参照項目の場合は参照先オブジェクト情報を含める
                if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    List<String> referenceObjects = new List<String>();
                    for (Schema.SObjectType refType : fieldDescribe.getReferenceTo()) {
                        referenceObjects.add(refType.getDescribe().getName());
                    }
                    metadata.put('referenceObjects', referenceObjects);
                }
                
                fieldMetadata.add(metadata);
            }
        }
        
        return fieldMetadata;
    }
    
    // フィールド値の型変換
    public Object convertFieldValue(Object value, Schema.DescribeFieldResult fieldDescribe) {
        if (value == null) {
            return null;
        }
        
        Schema.DisplayType fieldType = fieldDescribe.getType();
        String stringValue = String.valueOf(value);
        
        try {
            if (fieldType == Schema.DisplayType.BOOLEAN) {
                return Boolean.valueOf(stringValue);
            } else if (fieldType == Schema.DisplayType.DATE) {
                return Date.valueOf(stringValue);
            } else if (fieldType == Schema.DisplayType.DATETIME) {
                return DateTime.valueOf(stringValue.replace('T', ' ').replace('Z', ''));
            } else if (fieldType == Schema.DisplayType.DOUBLE || fieldType == Schema.DisplayType.PERCENT || fieldType == Schema.DisplayType.CURRENCY) {
                return Double.valueOf(stringValue);
            } else if (fieldType == Schema.DisplayType.INTEGER) {
                return Integer.valueOf(stringValue);
            } else if (fieldType == Schema.DisplayType.TIME) {
                // HH:mm:ss形式の文字列をTimeに変換
                List<String> parts = stringValue.split(':');
                return Time.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), Integer.valueOf(parts[2]), 0);
            } else {
                return stringValue;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Invalid value for field type ' + fieldType.name() + ': ' + stringValue);
        }
    }
    
    // SOSL検索クエリ構築
    public String buildSearchQuery(String objectApiName, List<String> fields, String searchTerm, String whereClause, Integer maxResults) {
        // 検索語句のエスケープ
        String escapedSearchTerm = String.escapeSingleQuotes(searchTerm);
        
        // 特殊文字をエスケープ
        escapedSearchTerm = escapedSearchTerm.replace('\\', '\\\\');
        escapedSearchTerm = escapedSearchTerm.replace('\'', '\\\'');
        escapedSearchTerm = escapedSearchTerm.replace('"', '\\"');
        
        // SOSL検索クエリ構築
        String searchQuery = 'FIND \'' + escapedSearchTerm + '*\' IN ALL FIELDS';
        searchQuery += ' RETURNING ' + objectApiName;
        searchQuery += '(' + String.join(fields, ', ');
        
        if (!String.isBlank(whereClause)) {
            searchQuery += ' WHERE ' + whereClause;
        }
        
        searchQuery += ' ORDER BY CreatedDate DESC';
        
        if (maxResults != null && maxResults > 0) {
            searchQuery += ' LIMIT ' + maxResults;
        } else {
            searchQuery += ' LIMIT 200';
        }
        
        searchQuery += ')';
        
        return searchQuery;
    }
}