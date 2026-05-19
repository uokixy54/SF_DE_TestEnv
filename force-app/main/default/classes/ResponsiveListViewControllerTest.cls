@isTest
private class ResponsiveListViewControllerTest {
    
    @testSetup
    static void setupTestData() {
        // テスト用のアカウントデータ作成
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 30; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Type = 'Prospect',
                Industry = 'Technology',
                Phone = '123-456-789' + i,
                AnnualRevenue = 1000000 + (i * 10000)
            ));
        }
        insert accounts;
        
        // テスト用のコンタクトデータ作成
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + acc.Name,
                Email = 'test' + acc.Id + '@example.com',
                AccountId = acc.Id
            ));
        }
        insert contacts;
    }
    
    @isTest
    static void testGetListViewData() {
        Test.startTest();
        
        // 基本的なデータ取得テスト
        Map<String, Object> result = ResponsiveListViewController.getListViewData(
            'Account',
            'Id, Name, Type, Industry',
            null,
            'Name ASC',
            10,
            1
        );
        
        Test.stopTest();
        
        // 結果検証
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(10, ((List<SObject>)result.get('records')).size(), 'Should return 10 records');
        System.assertEquals(30, result.get('totalRecords'), 'Total records should be 30');
        System.assertEquals(3, result.get('totalPages'), 'Total pages should be 3');
        System.assertEquals(1, result.get('pageNumber'), 'Page number should be 1');
        
        // フィールドメタデータの確認
        List<Map<String, Object>> fieldMetadata = (List<Map<String, Object>>)result.get('fieldMetadata');
        System.assertNotEquals(0, fieldMetadata.size(), 'Field metadata should not be empty');
    }
    
    @isTest
    static void testGetListViewDataWithWhere() {
        Test.startTest();
        
        // WHERE句を含むデータ取得テスト
        Map<String, Object> result = ResponsiveListViewController.getListViewData(
            'Account',
            'Id, Name, Type',
            'Type = \'Prospect\'',
            null,
            20,
            1
        );
        
        Test.stopTest();
        
        // 結果検証
        System.assertNotEquals(null, result, 'Result should not be null');
        List<SObject> records = (List<SObject>)result.get('records');
        for (SObject record : records) {
            System.assertEquals('Prospect', record.get('Type'), 'All records should have Type = Prospect');
        }
    }
    
    @isTest
    static void testGetListViewDataWithInvalidObject() {
        Test.startTest();
        
        Boolean exceptionThrown = false;
        try {
            ResponsiveListViewController.getListViewData(
                'InvalidObject',
                'Id, Name',
                null,
                null,
                10,
                1
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Error retrieving list view data'), 'Should throw appropriate error');
        }
        
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for invalid object');
    }
    
    @isTest
    static void testUpdateRecords() {
        // テストデータ取得
        List<Account> accounts = [SELECT Id, Name, Type FROM Account LIMIT 5];
        
        // レコード更新
        for (Account acc : accounts) {
            acc.Type = 'Customer';
        }
        
        Test.startTest();
        
        Map<String, Object> result = ResponsiveListViewController.updateRecords(accounts);
        
        Test.stopTest();
        
        // 結果検証
        System.assertEquals(true, result.get('success'), 'Update should be successful');
        System.assertEquals(5, result.get('successCount'), 'All 5 records should be updated');
        System.assertEquals(0, result.get('errorCount'), 'No errors should occur');
        
        // 実際のデータ確認
        List<Account> updatedAccounts = [SELECT Id, Type FROM Account WHERE Id IN :accounts];
        for (Account acc : updatedAccounts) {
            System.assertEquals('Customer', acc.Type, 'Type should be updated to Customer');
        }
    }
    
    @isTest
    static void testUpdateRecordsWithError() {
        // テストデータ取得
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        
        // 必須項目を空にして意図的にエラーを発生させる
        accounts[0].Name = '';
        
        Test.startTest();
        
        Map<String, Object> result = ResponsiveListViewController.updateRecords(accounts);
        
        Test.stopTest();
        
        // 結果検証
        System.assertEquals(true, result.get('success'), 'Operation should complete');
        System.assertEquals(1, result.get('successCount'), 'One record should succeed');
        System.assertEquals(1, result.get('errorCount'), 'One record should fail');
        
        List<Map<String, Object>> errorRecords = (List<Map<String, Object>>)result.get('errorRecords');
        System.assertEquals(1, errorRecords.size(), 'Should have one error record');
    }
    
    @isTest
    static void testBulkUpdateRecords() {
        // テストデータ取得
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
        List<String> recordIds = new List<String>();
        for (Account acc : accounts) {
            recordIds.add(acc.Id);
        }
        
        Test.startTest();
        
        Map<String, Object> result = ResponsiveListViewController.bulkUpdateRecords(
            recordIds,
            'Account',
            'Industry',
            'Finance'
        );
        
        Test.stopTest();
        
        // 結果検証
        System.assertEquals(true, result.get('success'), 'Bulk update should be successful');
        System.assertEquals(10, result.get('successCount'), 'All records should be updated');
        
        // 実際のデータ確認
        List<Account> updatedAccounts = [SELECT Id, Industry FROM Account WHERE Id IN :recordIds];
        for (Account acc : updatedAccounts) {
            System.assertEquals('Finance', acc.Industry, 'Industry should be updated to Finance');
        }
    }
    
    @isTest
    static void testBulkUpdateRecordsWithNoRecords() {
        Test.startTest();
        
        Boolean exceptionThrown = false;
        try {
            ResponsiveListViewController.bulkUpdateRecords(
                new List<String>(),
                'Account',
                'Industry',
                'Finance'
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('No records selected'), 'Should throw appropriate error');
        }
        
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for empty record list');
    }
    
    @isTest
    static void testGetObjectInfo() {
        Test.startTest();
        
        Map<String, Object> result = ResponsiveListViewController.getObjectInfo('Account');
        
        Test.stopTest();
        
        // 結果検証
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Account', result.get('label'), 'Label should be Account');
        System.assertEquals('Accounts', result.get('labelPlural'), 'Label plural should be Accounts');
        System.assertEquals('Account', result.get('apiName'), 'API name should be Account');
        System.assertEquals(true, result.get('isCreateable'), 'Account should be createable');
        System.assertEquals(true, result.get('isUpdateable'), 'Account should be updateable');
        System.assertEquals(true, result.get('isSearchable'), 'Account should be searchable');
        System.assertEquals(false, result.get('isCustom'), 'Account is not a custom object');
    }
    
    @isTest
    static void testSearchRecords() {
        Test.startTest();
        
        List<Map<String, Object>> result = ResponsiveListViewController.searchRecords(
            'Account',
            'Id, Name, Type',
            'Test',
            null,
            10
        );
        
        Test.stopTest();
        
        // 結果検証
        System.assertNotEquals(null, result, 'Result should not be null');
        // SOSL検索は非同期なのでテスト環境では結果が返らない可能性がある
        // そのため、エラーが発生しないことのみ確認
    }
    
    @isTest
    static void testSearchRecordsWithShortTerm() {
        Test.startTest();
        
        List<Map<String, Object>> result = ResponsiveListViewController.searchRecords(
            'Account',
            'Id, Name',
            'T',
            null,
            10
        );
        
        Test.stopTest();
        
        // 短い検索語の場合は空のリストが返される
        System.assertEquals(0, result.size(), 'Should return empty list for short search term');
    }
    
    @isTest
    static void testHelperValidateParameters() {
        ResponsiveListViewHelper helper = new ResponsiveListViewHelper();
        
        Test.startTest();
        
        // 正常なパラメータ
        try {
            helper.validateParameters('Account', 'Id, Name');
            System.assert(true, 'Should not throw exception for valid parameters');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for valid parameters');
        }
        
        // 空のオブジェクト名
        Boolean exceptionThrown = false;
        try {
            helper.validateParameters('', 'Id, Name');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Object API name is required'), 'Should throw appropriate error');
        }
        System.assert(exceptionThrown, 'Exception should be thrown for empty object name');
        
        // 空のフィールド
        exceptionThrown = false;
        try {
            helper.validateParameters('Account', '');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Fields to display are required'), 'Should throw appropriate error');
        }
        System.assert(exceptionThrown, 'Exception should be thrown for empty fields');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHelperConvertFieldValue() {
        ResponsiveListViewHelper helper = new ResponsiveListViewHelper();
        Schema.DescribeFieldResult fieldDescribe;
        
        Test.startTest();
        
        // Boolean型のテスト
        fieldDescribe = Account.IsDeleted.getDescribe();
        Object boolResult = helper.convertFieldValue('true', fieldDescribe);
        System.assertEquals(true, boolResult, 'Should convert string to boolean');
        
        // Date型のテスト
        fieldDescribe = Contact.Birthdate.getDescribe();
        Object dateResult = helper.convertFieldValue('2023-01-01', fieldDescribe);
        System.assertEquals(Date.newInstance(2023, 1, 1), dateResult, 'Should convert string to date');
        
        // Double型のテスト
        fieldDescribe = Account.AnnualRevenue.getDescribe();
        Object doubleResult = helper.convertFieldValue('12345.67', fieldDescribe);
        System.assertEquals(12345.67, doubleResult, 'Should convert string to double');
        
        // null値のテスト
        Object nullResult = helper.convertFieldValue(null, fieldDescribe);
        System.assertEquals(null, nullResult, 'Should handle null value');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSecurityChecks() {
        ResponsiveListViewHelper helper = new ResponsiveListViewHelper();
        
        Test.startTest();
        
        // オブジェクトアクセス権限チェック
        Boolean hasAccess = helper.hasObjectAccess('Account');
        System.assertEquals(true, hasAccess, 'Should have access to Account object');
        
        // オブジェクト更新権限チェック
        Boolean hasUpdateAccess = helper.hasUpdateAccess('Account');
        System.assertEquals(true, hasUpdateAccess, 'Should have update access to Account object');
        
        // フィールド更新権限チェック
        Boolean hasFieldUpdateAccess = helper.hasFieldUpdateAccess('Account', 'Name');
        System.assertEquals(true, hasFieldUpdateAccess, 'Should have update access to Name field');
        
        Test.stopTest();
    }
    
    @isTest
    static void testFieldParsing() {
        ResponsiveListViewHelper helper = new ResponsiveListViewHelper();
        
        Test.startTest();
        
        // 通常のフィールドパース
        List<String> fields = helper.parseFields('Name, Type, Industry');
        System.assertEquals(4, fields.size(), 'Should parse 3 fields plus Id');
        System.assert(fields.contains('Id'), 'Should automatically include Id field');
        System.assert(fields.contains('Name'), 'Should include Name field');
        System.assert(fields.contains('Type'), 'Should include Type field');
        System.assert(fields.contains('Industry'), 'Should include Industry field');
        
        // スペースを含むフィールドパース
        fields = helper.parseFields(' Name , Type , Industry ');
        System.assertEquals(4, fields.size(), 'Should handle spaces correctly');
        
        // Idフィールドが既に含まれている場合
        fields = helper.parseFields('Id, Name, Type');
        System.assertEquals(3, fields.size(), 'Should not duplicate Id field');
        
        Test.stopTest();
    }
}