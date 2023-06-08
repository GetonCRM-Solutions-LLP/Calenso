@isTest
private class ActivityWebserviceTest {
	@isTest static void testCreateActivity() {
        Lead lead = new Lead(FirstName='Tom',LastName='Wulmar',Email='tomwulmar243@gmail.com',MobilePhone='7086241583',Phone='7086241583',Company='Salesforce',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',UUId__c='poi');
        insert lead;
        
        Contact contact = new Contact(FirstName='Tom',LastName='Wulmar',Email='tomwulmar243@gmail.com',MobilePhone='95412684536',OtherPhone='8036521469',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',Title='VP Marketing',UUId__c='BOB');
        insert contact;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Activity';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"customer_uuid" : "WOS","end" : "2023-04-08T06:00:00.000+05:30","location" : "At Office","start" : "2023-04-08T03:00:00.000+05:30","body" : "SportKing, founded in 1998, is a start-up based in Austin, TX.","meeting_type" : "Meeting","uuid" : "plm","worker_email" : "marvin.felder@calenso.com"},{"customer_uuid" : "poi","end" : "2023-04-08T06:00:00.000+05:30","location" : "At Office","start" : "2023-04-08T03:00:00.000+05:30","body" : "SportKing, founded in 1998, is a start-up based in Austin, TX.","meeting_type" : "Meeting","uuid" : "ijn","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the createActivity method
        ActivityWebservice.createActivity();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(200, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(2, responseBody.size());
        Map<String,Object> firstContactResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstContactResponse.containsKey('success'));
    }
    
    @isTest static void testCreateErrorActivity() {
        Contact contact = new Contact(FirstName='Bob',LastName='Mark',Email='bobmark@gmail.com',MobilePhone='7412369885',OtherPhone='7410258963',Description='Sony, founded in 1789, is a start-up based in Dallas, TX.',Title='Director Sales',UUId__c='BOB');
        insert contact;
        
        Event event = new Event(WhoId=contact.Id,EndDateTime=System.today(),Location='CRS Block',StartDateTime=System.today(),Description='Edge sells its product through retailers and its own website.',Subject='Meeting',UUId__c='plm');
        insert event;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Activity';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"customer_uuid" : "ijn","end" : "2023-04-08T06:00:00.000+05:30","location" : "At Office","start" : "2023-04-08T03:00:00.000+05:30","body" : null,"meeting_type" : "Meeting","uuid" : null,"worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createActivity method
        ActivityWebservice.createActivity();
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
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Activity';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
       	// call the createActivity method
        ActivityWebservice.createActivity();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
    	System.assertEquals('Invalid JSON Format.', responseBody.get('error'));
    }
    
    @isTest static void testUpdateActivity() {
        Contact contact = new Contact(FirstName='Tom',LastName='Wulmar',Email='tomwulmar243@gmail.com',MobilePhone='95412684536',OtherPhone='8036521469',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',Title='VP Marketing',UUId__c='BUY');
        insert contact;
        
        Lead lead = new Lead(FirstName='Tom',LastName='Wulmar',Email='tomwulmar243@gmail.com',MobilePhone='7086241583',Phone='7086241583',Company='Salesforce',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',UUId__c='poi');
        insert lead;
        
        Event event = new Event(WhoId=contact.Id,EndDateTime=System.today(),Location='CRS Block',StartDateTime=System.today(),Description='Edge sells its product through retailers and its own website.',Subject='Meeting',UUId__c='plm');
        insert event;
        
        Event event1 = new Event(WhoId=lead.Id,EndDateTime=System.today(),Location='Nevada City',StartDateTime=System.today(),Description='Nintendo sells its product through retailers and its own website.',Subject='Meeting',UUId__c='yhn');
        insert event1;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Contact';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"customer_uuid" : "BUY","end" : "2023-04-08T06:00:00.000+05:30","location" : "At Office","start" : "2023-04-08T03:00:00.000+05:30","body" : "SportKing, founded in 1998, is a start-up based in Austin, TX.","meeting_type" : "Meeting","uuid" : "plm","worker_email" : "marvin.felder@calenso.com"},{"customer_uuid" : "poi","end" : "2023-04-08T06:00:00.000+05:30","location" : "At Office","start" : "2023-04-08T03:00:00.000+05:30","body" : "SportKing, founded in 1998, is a start-up based in Austin, TX.","meeting_type" : "Meeting","uuid" : "yhn","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
       	// call the updateActivity method
        ActivityWebservice.updateActivity();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(200, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(2, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('success'));
    }
    
    @isTest static void testUpdateErrorActivity() {
        Contact contact = new Contact(FirstName='Tom',LastName='Wulmar',Email='tomwulmar243@gmail.com',MobilePhone='95412684536',OtherPhone='8036521469',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',Title='VP Marketing',UUId__c='BUY');
        insert contact;
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Activity';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"customer_uuid" : "ijn","end" : "2023-04-08T06:00:00.000+05:30","location" : "At Office","start" : "2023-04-08T03:00:00.000+05:30","body" : null,"meeting_type" : "Meeting","uuid" : null,"worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
       	// call the updateActivity method
        ActivityWebservice.updateActivity();
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
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Activity';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
       	// call the updateActivity method
        ActivityWebservice.updateActivity();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
    	System.assertEquals('Invalid JSON Format.', responseBody.get('error'));
    }
    
    @isTest static void testDeleteActivity() {
        Lead lead = new Lead(FirstName='Tom',LastName='Wulmar',Email='tomwulmar243@gmail.com',MobilePhone='7086241583',Phone='7086241583',Company='Salesforce',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',UUId__c='poi');
        insert lead;
        
        Contact contact = new Contact(FirstName='Tom',LastName='Wulmar',Email='tomwulmar243@gmail.com',MobilePhone='95412684536',OtherPhone='8036521469',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',Title='VP Marketing',UUId__c='BOB');
        insert contact;
        
        Event event = new Event(WhoId=contact.Id,EndDateTime=System.today(),Location='CRS Block',StartDateTime=System.today(),Description='Edge sells its product through retailers and its own website.',Subject='Meeting',UUId__c='plm');
        insert event;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Activity';
        request.httpMethod = 'DELETE';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"customer_uuid" : "BOB","end" : "2023-04-08T06:00:00.000+05:30","location" : "At Office","start" : "2023-04-08T03:00:00.000+05:30","body" : "SportKing, founded in 1998, is a start-up based in Austin, TX.","meeting_type" : "Meeting","uuid" : "plm","worker_email" : "marvin.felder@calenso.com"},{"customer_uuid" : "poi","end" : "2023-04-08T06:00:00.000+05:30","location" : "At Office","start" : "2023-04-08T03:00:00.000+05:30","body" : "SportKing, founded in 1998, is a start-up based in Austin, TX.","meeting_type" : "Meeting","uuid" : "ijn","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the deleteActivity method
        ActivityWebservice.deleteActivity();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(200, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(2, responseBody.size());
        Map<String,Object> firstContactResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstContactResponse.containsKey('success'));
    }
    
    @isTest static void testDeleteErrorActivity() {
        Contact contact = new Contact(FirstName='Bob',LastName='Mark',Email='bobmark@gmail.com',MobilePhone='7412369885',OtherPhone='7410258963',Description='Sony, founded in 1789, is a start-up based in Dallas, TX.',Title='Director Sales',UUId__c='BOB');
        insert contact;
        
        Event event = new Event(WhoId=contact.Id,EndDateTime=System.today(),Location='CRS Block',StartDateTime=System.today(),Description='Edge sells its product through retailers and its own website.',Subject='Meeting',UUId__c='plm');
        insert event;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Activity';
        request.httpMethod = 'DELETE';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"customer_uuid" : "ijn","end" : "2023-04-08T06:00:00.000+05:30","location" : "At Office","start" : "2023-04-08T03:00:00.000+05:30","body" : null,"meeting_type" : "Meeting","uuid" : null,"worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the deleteActivity method
        ActivityWebservice.deleteActivity();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
    
    @isTest static void testDeleteNoRecordPassed() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Activity';
        request.httpMethod = 'DELETE';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the deleteActivity method
        ActivityWebservice.deleteActivity();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
    	System.assertEquals('Invalid JSON Format.', responseBody.get('error'));
    }
    
    
}