public with sharing class Tec_NewMainteEquipmentController {

    public class ParentRecordResult {
        @AuraEnabled public Object timeTest;
        @AuraEnabled public Id     child1RecordTypeId;
        @AuraEnabled public Id     child2RecordTypeId;
    }

    @AuraEnabled(cacheable=true)
    public static ParentRecordResult getParentRecord(Id parentRecordId) {
        TestObjectParent__c parentRecord = [
            SELECT Id, TimeTest__c
            FROM TestObjectParent__c
            WHERE Id = :parentRecordId
            LIMIT 1
        ];

        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.TestObjectChild__c
            .getRecordTypeInfosByDeveloperName();

        Schema.RecordTypeInfo child1RecordTypeInfo = recordTypeInfoMap.get('Child1Rec');
        Schema.RecordTypeInfo child2RecordTypeInfo = recordTypeInfoMap.get('Child2Rec');
        if (child1RecordTypeInfo == null || child2RecordTypeInfo == null) {
            throw new AuraHandledException('レコードタイプが見つかりません。開発者名を確認してください。');
        }

        ParentRecordResult result = new ParentRecordResult();
        result.timeTest           = parentRecord.TimeTest__c;
        result.child1RecordTypeId = child1RecordTypeInfo.getRecordTypeId();
        result.child2RecordTypeId = child2RecordTypeInfo.getRecordTypeId();
        return result;
    }
}
