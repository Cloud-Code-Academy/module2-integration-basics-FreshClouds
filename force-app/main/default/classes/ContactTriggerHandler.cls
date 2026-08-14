/**
 * ContactTrigger Trigger Description:
 * 
 * The ContactTrigger is designed to handle various logic upon the insertion and update of Contact records in Salesforce. 
 * 
 * Key Behaviors:
 * 1. When a new Contact is inserted and doesn't have a value for the DummyJSON_Id__c field, the trigger generates a random number between 0 and 100 for it.
 * 2. Upon insertion, if the generated or provided DummyJSON_Id__c value is less than or equal to 100, the trigger initiates the getDummyJSONUserFromId API call.
 * 3. If a Contact record is updated and the DummyJSON_Id__c value is greater than 100, the trigger initiates the postCreateDummyJSONUser API call.
 * 
 * Best Practices for Callouts in Triggers:
 * 
 * 1. Avoid Direct Callouts: Triggers do not support direct HTTP callouts. Instead, use asynchronous methods like @future or Queueable to make the callout.
 * 2. Bulkify Logic: Ensure that the trigger logic is bulkified so that it can handle multiple records efficiently without hitting governor limits.
 * 3. Avoid Recursive Triggers: Ensure that the callout logic doesn't result in changes that re-invoke the same trigger, causing a recursive loop.
 * 
 * Optional Challenge: Use a trigger handler class to implement the trigger logic.
 */

	// When a contact is inserted
	// if DummyJSON_Id__c is null, generate a random number between 0 and 100 and set this as the contact's DummyJSON_Id__c value

	//When a contact is inserted
	// if DummyJSON_Id__c is less than or equal to 100, call the getDummyJSONUserFromId API

	//When a contact is updated
	// if DummyJSON_Id__c is greater than 100, call the postCreateDummyJSONUser API
public with sharing class ContactTriggerHandler {
    public static void Run(TriggerOperation operation, List<Contact> triggerDotNew, Map<Id, Contact> triggerDotOldMap) {
		try {
            switch on operation {
                when BEFORE_INSERT{
					setIntialDummyJSONId(triggerDotNew);
                }
                when AFTER_INSERT {
					processSyncDummyJSON(triggerDotNew);
                }
				when AFTER_UPDATE {
					processNewDummyJSONUserId(triggerDotNew);
				}
            }
        } catch (Exception e) {
            System.debug(e);
            throw e;
        }
    }
	private static void setIntialDummyJSONId(List<Contact> cons) {
		for(Contact c: cons) {
			System.debug(c.DummyJson_Id__c);
			c.DummyJson_Id__c = (String.isBlank(c.DummyJSON_Id__c)) ? generateRandomDummyJsonId() : c.DummyJSON_Id__c;
		}
	}
	private static void processSyncDummyJSON(List<Contact> cons) {
		List<Id> contactIds = new List<Id>();
		for(Contact c: cons) {
			contactIds.add(c.Id);
		}
		DummyJSONCallout_Queuable.enqueueDummyJSONCallout(contactIds);
	}
	private static void processNewDummyJSONUserId(List<Contact> cons){
		processSyncDummyJSON(cons);
	}
	private static String generateRandomDummyJsonId() {
		Integer min = 31;
		//Give space for the native API already existing numbers else duplication and overwrites will occur there are 30 existing users per https://dummyjson.com/users they are immutable and non removable.
		Integer max = 100;
		return String.valueOf((Integer)(Math.random() * (max - min + 1)) + min);
	}
}
