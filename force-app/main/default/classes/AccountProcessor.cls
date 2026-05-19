public with sharing class AccountProcessor {
    @future
    public static void countContacts(Set<Id> accountIds) {
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT
                Id
                ,(
                    SELECT
                        Id
                    FROM
                        contacts
                )
            FROM
                Account
            WHERE
                Id IN: accountIds
        ]);
    }
}