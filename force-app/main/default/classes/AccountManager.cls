@RestResource(urlMapping='/Accounts/*/contacts')
global with sharing class AccountManager {
    @HttpGet
    global static Account getAccount() {
        RestRequest request = RestContext.request;
        // grab the accountId from the end of the URL
        String accountId = request.requestURI.substring(request.requestURI.lastIndexOf('/') - 18, request.requestURI.lastIndexOf('/'));
        Account result = [
            SELECT
                Id
                ,Name
                ,(
                    SELECT
                        Id
                        ,Name
                    FROM
                        Contacts
                )
            FROM 
                Account
            WHERE 
                Id = :accountId
            ];
        return result;
    }
}