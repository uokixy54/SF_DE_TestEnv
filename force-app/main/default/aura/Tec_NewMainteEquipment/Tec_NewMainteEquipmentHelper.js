({
    handleInit : function(component) {
        console.log("doInit process started!");
        var pageRef = component.get("v.pageReference");
        console.log("pageRef", pageRef);
        if (!pageRef) {
            console.error("Failed to retrieve the page data.");
            return;
        }

        var state             = pageRef.state;
        var encodedContextRef = state ? state.inContextOfRef : null;
        console.log("state", state);
        console.log("inContextOfRef", encodedContextRef);

        if (!encodedContextRef || !encodedContextRef.startsWith("1.")) {
            console.log("[DEBUG] inContextOfRef なし → 標準New へ");
            this.navigateToStandardNew(pageRef);
            return;
        }

        try {
            var contextPageRef = JSON.parse(window.atob(encodedContextRef.substring(2)));
            console.log("[DEBUG] decoded inContextOfRef", contextPageRef);

            if (contextPageRef.type !== "standard__recordPage" || !contextPageRef.attributes || !contextPageRef.attributes.recordId) {
                console.log("[DEBUG] 親レコードページ以外からのNew → 標準New へ", contextPageRef.type);
                this.navigateToStandardNew(pageRef);
                return;
            }

            console.log("[DEBUG] 親レコードID取得成功:", contextPageRef.attributes.recordId);
            component.set("v.parentRecordId", contextPageRef.attributes.recordId);
            component.set("v.originPageRef",  contextPageRef);

            this.fetchParentRecordAndOpen(component, pageRef, contextPageRef.attributes.recordId);

        } catch (e) {
            console.error("[DEBUG] inContextOfRef デコード失敗:", e);
            this.navigateToStandardNew(pageRef);
        }
    },

    fetchParentRecordAndOpen : function(component, pageRef, parentRecordId) {
        console.log("[DEBUG] Apex呼び出し開始: getParentRecord");
        var self   = this;
        var action = component.get("c.getParentRecord");
        action.setParams({ parentRecordId: parentRecordId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var apexResult       = response.getReturnValue();
                var childRecordTypeId = apexResult.timeTest
                    ? apexResult.child1RecordTypeId
                    : apexResult.child2RecordTypeId;
                console.log("[DEBUG] Apex成功 apexResult:", apexResult);
                console.log("[DEBUG] timeTest:", apexResult.timeTest);
                console.log("[DEBUG] 使用するchildRecordTypeId:", childRecordTypeId);
                self.openChildRecordCreate(pageRef, childRecordTypeId, component.get("v.parentRecordId"));
            } else if (state === "ERROR") {
                console.error("[DEBUG] Apex失敗 ERROR:", response.getError());
                self.navigateToStandardNew(pageRef);
            } else if (state === "INCOMPLETE") {
                console.error("[DEBUG] Apex失敗 INCOMPLETE: サーバーからの応答なし");
                self.navigateToStandardNew(pageRef);
            }
        });
        $A.enqueueAction(action);
    },

    // 通常New：標準と同じ挙動（レコードタイプ選択含む）
    navigateToStandardNew : function(pageRef) {
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            entityApiName: pageRef.attributes.objectApiName
        });
        createRecordEvent.fire();
    },

    // 関連リストからのNew：レコードタイプと親IDを指定して開く
    openChildRecordCreate : function(pageRef, childRecordTypeId, parentRecordId) {
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            entityApiName     : pageRef.attributes.objectApiName,
            recordTypeId      : childRecordTypeId,
            defaultFieldValues: {
                'TestObjectParent1__c': parentRecordId
            }
        });
        createRecordEvent.fire();
    },

})
