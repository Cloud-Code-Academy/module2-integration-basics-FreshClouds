public with sharing class DummyJSONCallout_Queuable implements Queueable, Database.AllowsCallouts{

    private static final Integer MAX_BATCH_SIZE = 50;//under callout limit per job
    private List<Id> contactIds;
    private Integer startIndex;

    public DummyJSONCallout_Queuable(List<Id> contactIds) {
        this(contactIds, 0);
    }
    public DummyJSONCallout_Queuable(List<Id> contactIds, Integer startIndex){
        this.contactIds = contactIds == null ? new List<Id>() : new List<Id>(contactIds);
        this.startIndex = startIndex == null ? 0 : startIndex;
    }
    public static void enqueueDummyJSONCallout(List<Id> contactIds){
        if(contactIds ==  null || contactIds.isEmpty()){
            return;
        }
        List<Id> dedupedIds = new List<Id>(new Set<Id>(contactIds));
        System.enqueueJob(new DummyJSONCallout_Queuable(dedupedIds), 0);
    }

    public void execute(QueueableContext context) {
        if(contactIds == null || contactIds.isEmpty() || startIndex >= contactIds.size()){
            return;
        }
        Integer endIndex = Math.min(startIndex + MAX_BATCH_SIZE, contactIds.size());
        List<Id> currentChunkIds = sliceCollection(contactIds, startIndex, endIndex);
        List<Contact> contacts = [
            SELECT  Id, DummyJSON_Id__c,
                    FirstName, LastName, GenderIdentity, BirthDate,
                    Email, Phone,
                    MailingStreet, MailingCity, MailingState, MailingPostalCode
            FROM Contact
            WHERE Id IN :currentChunkIds
            AND DummyJSON_Id__c != null
            WITH USER_MODE
        ];
        if(contacts.isEmpty()){
            enqueueNextChunkIfNeeded(endIndex);
            return;
        }
        for(Contact c : contacts){
            if(c.DummyJSON_Id__c != null && Integer.valueOf(c.DummyJSON_Id__c) <= 100 ){
                DummyJSONCallout.getDummyJSONUserFromId(c.DummyJSON_Id__c);
            }
            if(c.DummyJSON_Id__c != null && Integer.valueOf(c.DummyJSON_Id__c) > 100 ) {
                DummyJSONCallout.postCreateDummyJSONUser(c);
            }
        }
        enqueueNextChunkIfNeeded(endIndex);
    }
    private void enqueueNextChunkIfNeeded(Integer nextStartIndex){
        if(nextStartIndex < contactIds.size()){
            System.enqueueJob(new DummyJSONCallout_Queuable(contactIds, nextStartIndex));
        }
    }
    private static List<Id> sliceCollection(List<Id> ids, Integer startingIndex, Integer endIndex){
        List<Id> result = new List<Id>();
        if(ids == null || ids.isEmpty()){
            return result;
        }
        Integer safeStart = Math.max(0, startingIndex);
        Integer safeEnd = Math.min(endIndex, ids.size());
        for(Integer i = safeStart; i < safeEnd; i++){
            result.add(ids[i]);
        }
        return result;
    }
}