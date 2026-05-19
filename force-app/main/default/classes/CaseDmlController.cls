public with sharing class CaseDmlController {
    @AuraEnabled(cacheable=false)
    public static List<Case> getCases(){
        try {
            return [SELECT Id, CaseNumber, Subject FROM Case ORDER BY CreatedDate DESC LIMIT 5];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateCases(List<Case> cases) {
        try {
            update cases;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    } 
}