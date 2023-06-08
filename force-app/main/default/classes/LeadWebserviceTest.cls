@isTest
private class LeadWebserviceTest {
    @isTest
    static void testCheckEmailPhone() {
        // Create test data
        List<Object> oldObject = new List<Object>{
            new Map<String, Object>{'email' => 'test1@test.com', 'phone' => '1234567890', 'uuid' => '1'},
            new Map<String, Object>{'email' => 'test2@test.com', 'phone' => '2345678901', 'uuid' => '2'},
            new Map<String, Object>{'email' => 'test3@test.com', 'phone' => '3456789012', 'uuid' => '3'}
        };
        insert new Lead(Email = 'test1@test.com', Phone = '1234567890', Status = 'Open - Not Contacted', LastName = 'Doe', Company = 'Acme');
        insert new Lead(Email = 'test2@test.com', Phone = '1234567890', Status = 'Closed - Converted', LastName = 'Smith', Company = 'Widgets');

        Test.startTest();
        // Call the method to test
        Map<String,Object> result = LeadWebservice.checkemailphone(oldObject);
        Test.stopTest();

        // Verify the result
        System.assertEquals(new Set<String>{'test1@test.com'}, (Set<String>)result.get('emailmap'));
        System.assertEquals(new Set<String>{'1234567890'}, (Set<String>)result.get('phonemap'));
        //System.assertEquals(new Map<String, String>{'1' => [SELECT Id FROM Lead WHERE Email = 'test1@test.com'].Id}, (Map<String, String>)result.get('existingleaddatamap'));
    }
    
    
    @isTest static void testCreateLead() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Lead';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "Bob","lastname" : "Vance","email" : "bobvance123@gmail.com","mobile" : 9852364186,"phone" : 7086241583,"company_name" : "Calenso","title" : "VP Sales","body" : "Google, founded in 1899, is a start-up based in Austin, TX. The company designs and manufactures a device to convert music from one digital format to another. Edge sells its product through retailers and its own website.","uuid" : "WOS","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the createLead method
        LeadWebservice.createLead();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(200, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('success'));
    }
    
    @isTest static void testCreateLeadRecordExisted() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Lead';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"id": "00Q0900000JZc85EAD","prename" : "Bob","lastname" : "Vance","email" : "bobvance@gmail.com","mobile" : 9852361236,"phone" : 7086241583,"company_name" : "Calenso","title" : "VP Sales","body" : "Google, founded in 1899, is a start-up based in Austin, TX. The company designs and manufactures a device to convert music from one digital format to another. Edge sells its product through retailers and its own website.","uuid" : "WOS","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the createLead method
        LeadWebservice.createLead();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
  
    @isTest static void testCreateErrorLead() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Lead';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "Bob","lastname" : null,"email" : "bobvance123@gmail.com","mobile" : 9852364186,"phone" : 7086241583,"company_name" : "Salesforce","title" : "VP Sales","body" : "Google, founded in 1899, is a start-up based in Austin, TX. The company designs and manufactures a device to convert music from one digital format to another. Edge sells its product through retailers and its own website.","uuid" : "WOS","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createLead method
        LeadWebservice.createLead();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('error'));
    }
    
    @isTest static void testCreateUserNotFound() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Lead';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "Bob","lastname" : "Vance","email" : "bobvance123@gmail.com","mobile" : 9852364186,"phone" : 7086241583,"company_name" : "Calenso","title" : "VP Sales","body" : "Google, founded in 1899, is a start-up based in Austin, TX. The company designs and manufactures a device to convert music from one digital format to another. Edge sells its product through retailers and its own website.","uuid" : "NJI","worker_email" : "demo@gmail.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createLead method
        LeadWebservice.createLead();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(false, firstLeadResponse.containsKey('errorMessage'));
    }
    
    @isTest static void testCreateNoRecordPassed() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Lead';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the createLead method
        LeadWebservice.createLead();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
    	System.assertEquals('Invalid JSON Format.', responseBody.get('error'));
    }
    
    @isTest static void testUpdateLead() {
         Lead lead = new Lead(FirstName='Tom',LastName='Wulmar',Email='tomwulmar243@gmail.com',MobilePhone='7086241583',Phone='7086241583',Company='Salesforce',Description='Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.',UUId__c='poi');
        insert lead;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Lead';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"uuid" : "poi","prename" : "Tom","lastname" : "Wulmar","email" : "tomwulmar243@gmail.com","mobile" : 7086241583,"phone" : 7086241583,"company_name" : "Salesforce","title" : "VP Marketing","body" : "Nintendo, founded in 1789, is a start-up based in Dallas, TX. Nintendo sells its product through retailers and its own website.","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateLead method
        LeadWebservice.updateLead();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(200, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstLeadResponse.containsKey('success'));
    }
    
    @isTest static void testUpdateErrorLead() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Lead';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"prename" : "Bob","lastname" : null,"email" : "bobvance123@gmail.com","mobile" : 9852364186,"phone" : 7086241583,"company_name" : "Salesforce","title" : "VP Sales","body" : "Google, founded in 1899, is a start-up based in Austin, TX. The company designs and manufactures a device to convert music from one digital format to another. Edge sells its product through retailers and its own website.","uuid" : null,"worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateLead method
        LeadWebservice.updateLead();
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
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Lead';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateLead method
        LeadWebservice.updateLead();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
    	System.assertEquals('Invalid JSON Format.', responseBody.get('error'));
    }
}