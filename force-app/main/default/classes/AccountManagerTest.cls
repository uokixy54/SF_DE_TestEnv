@IsTest
private class AccountManagerTest {
    @isTest static void testGetAccount() {
        Id recordId = createTestRecord();
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = 'https://lemberry-dev-ed.develop.my.salesforce.com/services/apexrest/Accounts/' + recordId + '/contacts';
        request.httpMethod = 'GET';
        RestContext.request = request;
        // Call the method to test
        Account thisAccount = AccountManager.getAccount();
        // Verify results
        Assert.isTrue(thisAccount != null);
    }

    static Id createTestRecord() {
        // Create test record
        Account accountTest = new Account(Name = 'Test');
        insert accountTest;
        Contact contactTest = new Contact(LastName = 'Test', AccountId = accountTest.Id);
        insert contactTest;
        return accountTest.Id;
    }
}