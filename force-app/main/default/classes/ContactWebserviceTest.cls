@isTest
private class ContactWebserviceTest {

    @isTest
    static void testCheckEmailPhone() {
        // Create test lead and contact records
        Lead testLead = new Lead(FirstName='Test', LastName='Lead', Company='Salesforce', Email='testlead@test.com', Phone='(123) 456-7890', Status='Open - Not Contacted');
        insert testLead;
        Contact testContact = new Contact(FirstName='Test', LastName='Contact', Email='testcontact@test.com', OtherPhone='(987) 654-3210');
        insert testContact;
        
        // Create test data list
        List<Object> testData = new List<Object>();
        Map<String,Object> leadData = new Map<String,Object>();
        leadData.put('uuid', '123');
        leadData.put('email', 'testlead@test.com');
        leadData.put('phone', '(123) 456-7890');
        testData.add(leadData);
        Map<String,Object> contactData = new Map<String,Object>();
        contactData.put('uuid', '456');
        contactData.put('email', 'testcontact@test.com');
        contactData.put('phone', '(987) 654-3210');
        testData.add(contactData);
        
        // Call checkemailphone method
        Map<String,Object> result = ContactWebservice.checkemailphone(testData);

        // Verify email and phone sets contain correct values
        System.assertEquals(new Set<String>{'testlead@test.com'}, (Set<String>)result.get('emailmap'));
        System.assertEquals(new Set<String>{'(123) 456-7890'}, (Set<String>)result.get('phonemap'));
        System.assertEquals(new Set<String>{'testcontact@test.com'}, (Set<String>)result.get('emailcontactmap'));
        System.assertEquals(new Set<String>{'(987) 654-3210'}, (Set<String>)result.get('phonecontactmap'));
        
        // Verify existing data maps contain correct values
        Map<String,String> leadExistingDataMap = (Map<String,String>)result.get('existingleaddatamap');
        Map<String,String> contactExistingDataMap = (Map<String,String>)result.get('existingcontactdatamap');
        System.assertEquals(1, leadExistingDataMap.size());
        System.assertEquals(testLead.Id, leadExistingDataMap.get('123'));
        System.assertEquals(1, contactExistingDataMap.size());
        System.assertEquals(testContact.Id, contactExistingDataMap.get('456'));
    }
    
    @isTest static void testCreateContact() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "Riddick","lastname" : "Tom","email" : "tomriddick420@gmail.com","phone" : 8036521469,"mobile" : 95412684536,"title" : "VP, Sales","remarks" : "SportKing, founded in 1998, is a start-up based in Austin, TX.","uuid" : "WOS","birthday" : "2023-03-21","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the createContact method
        ContactWebservice.createContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(200, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstContactResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstContactResponse.containsKey('success'));
    }
    
    @isTest static void testCreateErrorContact() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "Bob","lastname" : "Tom","email" : "tombob1@gmail.com","phone" : 2314569874,"mobile" : 3654123698,"title" : "Director, Service","remarks" : "SportKing, founded in 1998, is a start-up based in Austin, TX.","uuid" : null,"birthday" : "3/21/2023","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createContact method
        ContactWebservice.createContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
    
    @isTest static void testCreateErrorUUIdNullContact() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "Bob","email" : null,"phone" : 8036521469,"mobile" : 95412684536,"title" : "VP, Sales","remarks" : null,"uuid" : "WOS","birthday" : "3/21/2023","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createContact method
        ContactWebservice.createContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
    
    @isTest static void testCreateContactRecordExisted() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"id": "0030900001KmtUHAAZ","prename" : "James","lastname" : "Wulmar","email" : "jamesm@gmail.com","phone" : 1587815685,"mobile" : 2012684721,"title" : "Director, Sales","remarks" : "Texspin, founded in 1990, is a start-up based in Turkey. Texspin sells its product through retailers and its own website.","uuid" : "ttp","birthday" : "4/24/2023","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createContact method
        ContactWebservice.createContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
    
    @isTest static void testInvalidDateCreate() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "James","lastname" : "gary","email" : "jamgary@gmail.com","phone" : 1587741685,"mobile" : 2085284721,"title" : "Director, Sales","remarks" : "Texspin, founded in 1990, is a start-up based in Turkey. Texspin sells its product through retailers and its own website.","uuid" : "ttpp","birthday" : "4-24-2023","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createContact method
        ContactWebservice.createContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
    
    @isTest static void testUpdateErrorUUIdNullContact() {
        Contact contact = new Contact(FirstName='Tom',LastName='Wulmar',Birthdate=Date.valueOf('2023-04-24'),Email='tomwulmar243@gmail.com',MobilePhone='95412684536',OtherPhone='8036521469',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',Title='VP Marketing',UUId__c='WOS');
        insert contact;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "Bob","email" : null,"phone" : 8036521469,"mobile" : 95412684536,"title" : "VP, Sales","remarks" : null,"uuid" : null,"birthday" : "3/21/2023","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the updateContact method
        ContactWebservice.updateContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
    
    @isTest static void testCreateNoRecordPassed() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the createContact method
        ContactWebservice.createContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
    	System.assertEquals('Invalid JSON Format.', responseBody.get('error'));
    }
    
    @isTest static void testUpdateContact() {
        Contact contact = new Contact(FirstName='Tom',LastName='Wulmar',Birthdate=Date.valueOf('2023-04-24'),Email='tomwulmar243@gmail.com',MobilePhone='95412684536',OtherPhone='8036521469',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',Title='VP Marketing',UUId__c='WOS');
        insert contact;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"uuid" : "WOS","prename" : "Tom","lastname" : "Wulmar","birthday": "2023-03-21","email" : "tomwulmar243@gmail.com","mobile" : 95412684536,"phone" : 8036521469,"title" : "VP Marketing","body" : "Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateContact method
        ContactWebservice.updateContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(200, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('success'));
    }
    
    @isTest static void testUpdateInvalidDateContact() {
        Contact contact = new Contact(FirstName='Tom',LastName='Wulmar',Birthdate=Date.valueOf('2023-04-24'),Email='tomwulmar243@gmail.com',MobilePhone='95412684536',OtherPhone='8036521469',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',Title='VP Marketing',UUId__c='WOS');
        insert contact;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"uuid" : "WOS","prename" : "Tom","lastname" : "Wulmar","birthday": "4-24-2023","email" : "tomwulmar243@gmail.com","mobile" : 95412684536,"phone" : 8036521469,"title" : "VP Marketing","body" : "Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateContact method
        ContactWebservice.updateContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
    
    @isTest static void testUpdateErrorContact() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "Riddick","email" : null,"phone" : null,"mobile" : 95412684536,"title" : "VP, Sales","remarks" : null,"uuid" : "WOS","birthday" : "3/21/2023","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateContact method
        ContactWebservice.updateContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
    
    @isTest static void testUpdateNoRecordPassed() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Contact';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateContact method
        ContactWebservice.updateContact();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
    	System.assertEquals('Invalid JSON Format.', responseBody.get('error'));
    }
}