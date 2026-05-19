public with sharing class Sls_ReplaceAssetController {
    @AuraEnabled
    public static TestObjectParent__c getParentObjInfo(Id parentId){
        try {
            TestObjectParent__c p = [
                SELECT
                    Id
                    ,Field1__c
                    ,Name
                    ,RichTextAreaTest__c
                    ,TestAutoNumber__c
                    ,TestObjectParentCode__c
                    ,TextEncryptionTest__c
                    ,TimeTest__c
                FROM
                    TestObjectParent__c
                WHERE
                    Id =: parentId
            ];

            return p;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id handleCreateParent(String fields, Id originRecId){
        try {
            TestObjectParent__c newCopiedRec = (TestObjectParent__c)JSON.deserialize(fields, TestObjectParent__c.class);
            insert newCopiedRec;

            TestObjectChild__c c = new TestObjectChild__c(Name='テスト子999999999',TestObjectParent1__c=newCopiedRec.Id);
            insert c;

            TestObjectParent__c p = new TestObjectParent__c(Id=originRecId, CopiedFLG__c=true);
            update p;
            
            return newCopiedRec.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}