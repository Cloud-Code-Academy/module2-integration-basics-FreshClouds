trigger ContactTrigger on Contact(before insert, after insert) {
	ContactTriggerHandler.Run(Trigger.operationType, Trigger.new, Trigger.oldMap);
}