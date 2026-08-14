/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */
public with sharing class DummyJSONCallout {
	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */

	public static void getDummyJSONUserFromId(String dummyUserId) {
		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:DummyJsonUser/users/' +dummyUserId);
		req.setMethod('GET');
		HttpResponse res = new Http().send(req);
		Contact con = new Contact();
		if (res != null && res.getStatusCode() == 200) {
			con = createContactFromJson(res.getBody());
		}
		Database.upsert(con, Contact.DummyJSON_Id__c, AccessLevel.USER_MODE);
	}

	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static Contact createContactFromJson(String jsonResponse) {
		Map<String, Object> jsonUserMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
		Map<String, Object> jsonUserAddress = (Map<String, Object>)jsonUserMap.get('address');
		Contact con = new Contact(
			FirstName = (String)jsonUserMap.get('firstName'),
			LastName = (String)jsonUserMap.get('lastName'),
			Email = (String)jsonUserMap.get('email'),
			GenderIdentity = (String)jsonUserMap.get('gender'),
			DummyJSON_Id__c = String.valueOf(jsonUserMap.get('id')),
			Phone = (String)jsonUserMap.get('phone'),
			Birthdate = Date.valueOf((String)jsonUserMap.get('birthDate')),
			MailingStreet = (String)jsonUserAddress.get('address'),
			MailingCity = (String)jsonUserAddress.get('city'),
			MailingState = (String)jsonUserAddress.get('state'),
			MailingPostalCode = (String)jsonUserAddress.get('postalCode'),
			MailingCountry = (String)jsonUserAddress.get('country')
		);
		return con;
	}

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	
	/*Based on my choices of building with Queueuable
	* this should be accepting a Contact not an ID 
	* but then I would have to change the test also so accepting the additional query
	*/
	public static void postCreateDummyJSONUser(String contactId) {
		HttpRequest req = generateBaseUserAddRequest();
		req.setBody(generateDummyJsonUserPayload(contactId));
		HttpResponse res = new Http().send(req);
		if(res.getStatusCode() >= 200 && res.getStatusCode() < 300){
			Contact con = new Contact(
				Id = contactId,
				DummyJSON_Last_Updated__c = System.now()
			);
			update as user con;
		}
	}
	public static void postCreateDummyJSONUser(Contact con) {
		HttpRequest req = generateBaseUserAddRequest();
		req.setBody(generateDummyJsonUserPayload(con));
		HttpResponse res = new Http().send(req);
		if(res.getStatusCode() >= 200 && res.getStatusCode() < 300){
			con.DummyJSON_Last_Updated__c = System.now();
			update as user con;
		}
	}

	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static String generateDummyJsonUserPayload(String contactId) {
		// Query the contact to get the field values to generate the JSON payload.
		Contact con = [SELECT	
			Id, DummyJSON_Id__c,
			FirstName, LastName, GenderIdentity, BirthDate,
			Email, Phone,
			MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
			FROM Contact
			WHERE Id = :contactId
			AND DummyJSON_Id__c != null
			WITH USER_MODE
			LIMIT 1];
		return generateDummyJsonUserPayload(con);
	}
	private static String generateDummyJsonUserPayload(Contact con) {
		Map<String, Object> conMap = new Map<String, Object>{
			'salesforceId' => blankValueChecker(con.Id),
			'firstName' => blankValueChecker(con.FirstName),
			'lastName' => blankValueChecker(con.LastName),
			'gender' => blankValueChecker(con.GenderIdentity),
			'email' => blankValueChecker(con.Email),
			'phone' => blankValueChecker(String.valueOf(con.Phone))
		};
		return JSON.serialize(conMap);
		// Make sure to check that required contacts fields have a value. Default the value to unknown if it does not exists.
		// Integration data can change over time. It is a best practice to add safeguards/validation to ensure the integration does not break.
	}
	private static HttpRequest generateBaseUserAddRequest(){
		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:DummyJsonUser/users/add');
		req.setMethod('POST');
		return req;
	}
	private static String blankValueChecker(String str) {
		return (String.isBlank(str))? 'unknown' : str;
	}
}