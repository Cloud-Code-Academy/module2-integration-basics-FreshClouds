trigger ContactTrigger on Contact(before insert) {
	ContactTriggerHandler.Run(Trigger.operationType, Trigger.new, Trigger.oldMap);
}