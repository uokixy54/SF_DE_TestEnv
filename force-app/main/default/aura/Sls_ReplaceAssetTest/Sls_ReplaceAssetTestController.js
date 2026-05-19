({
    doInit : function(component, event, helper) {
        var action = component.get("c.getParentObjInfo");
        var parentObjId = component.get("v.recordId");

        action.setParams({ "parentId": parentObjId });

        action.setCallback(this, function(data) {
            var value = data.getReturnValue();
            if (value == null) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "specific parent object record not found.",
                    "type": "error",
                });
                toastEvent.fire();
            } else {
                component.set("v.isLoading", false);
            }
            // var closeActionPannel = $A.get("e.force:closeQuickAction");
            // closeActionPannel.fire();
        });
        $A.enqueueAction(action);
    },

    handleSubmit: function(component, event, helper) {
        event.preventDefault();

        var fields = event.getParam("fields");

        // changed while loading
        component.set("v.isLoading", true);

        var action = component.get("c.handleCreateParent");
        action.setParams({
            fields: JSON.stringify(fields),
            originRecId: component.get("v.recordId"),
        });
        action.setCallback(this, function(data) {
            var state = data.getState();
            if (state === "SUCCESS") {
                var newRecordId = data.getReturnValue();
                $A.get("e.force:closeQuickAction").fire();
                var navEvent = $A.get("e.force:navigateToSObject");
                navEvent.setParams({ recordId: newRecordId });
                navEvent.fire();
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "unknown error occurred.",
                    "type": "error",
                });
                toastEvent.fire();

                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    }
})