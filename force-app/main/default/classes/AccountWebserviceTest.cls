@isTest
private class AccountWebserviceTest {
    @isTest
	static void testCheckName() {
        // Create test data
        List<Object> oldObject = new List<Object>{
            new Map<String, Object>{'company_name' => 'Acme', 'uuid' => '1'},
            new Map<String, Object>{'company_name' => 'Widgets', 'uuid' => '2'},
            new Map<String, Object>{'company_name' => 'Initech', 'uuid' => '3'}
        };
        insert new Account(Name = 'Acme', Industry = 'Technology');
        insert new Account(Name = 'Widgets', Industry = 'Manufacturing');
    
        Test.startTest();
        // Call the method to test
        Map<String,Object> result = AccountWebservice.checkname(oldObject);
        Test.stopTest();
    
        // Verify the result
        System.assertEquals(new Set<String>{'Acme', 'Widgets'}, (Set<String>)result.get('namemap'));
        System.assertEquals(new Map<String, String>{'1' => [SELECT Id FROM Account WHERE Name = 'Acme'].Id, '2' => [SELECT Id FROM Account WHERE Name = 'Widgets'].Id}, (Map<String, String>)result.get('existingaccountdatamap'));
	}
    
    @isTest static void testCreateAccount() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Account';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"company_name" : "Salesoforce","city" : "Texas","zip" : "315682","street" : "9 Bold Lane","phone" : 9523658523,"customer_type_id" : "Prospect","url" : "www.salesforce.com","uuid" : "WOS","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the createAccount method
        AccountWebservice.createAccount();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(200, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstAccountResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstAccountResponse.containsKey('success'));
    }
    
    @isTest static void testCreateErrorAccount() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Account';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"customer_type_id" : null,"url" : "www.calenso.com","uuid" : null,"worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createAccount method
        AccountWebservice.createAccount();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstAccountResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstAccountResponse.containsKey('error'));
    }
    
    @isTest static void testCreateCompanyNameNullAccount() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Account';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"company_name" : null,"customer_type_id" : null,"url" : "www.calenso.com","uuid" : "WOS","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createAccount method
        AccountWebservice.createAccount();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstAccountResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstAccountResponse.containsKey('error'));
    }
    
    @isTest static void testCreateNoRecordPassed() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Account';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the createAccount method
        AccountWebservice.createAccount();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
    	System.assertEquals('Invalid JSON Format.', responseBody.get('error'));
    }
    
    @isTest static void testCreateUserNotFound() {
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Account';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"company_name" : "Calenso","customer_type_id" : "Prospect","url" : "www.calenso.com","uuid" : "WOSP","worker_email" : "demo@gmail.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;  
        
        Test.startTest();
        // call the createAccount method
        AccountWebservice.createAccount();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstLeadResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(false, firstLeadResponse.containsKey('errorMessage'));
    }
    
    @isTest static void testUpdateAccount() {
        Account account = new Account(Name='Salesoforce',Phone='9523658523',UUId__c='WOS',Website='www.salesforce.com',Type='Prospect',BillingStreet='9 Bold Lane',BillingCity='Texas',BillingPostalCode='315682');
        insert account;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Account';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"company_name" : "Salesoforce","city" : "Texas","zip" : "315682","street" : "9 Bold Lane","phone" : 9523658523,"customer_type_id" : "Prospect","url" : "www.salesforce.com","uuid" : "WOS","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateAccount method
        AccountWebservice.updateAccount();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(200, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstAccountResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstAccountResponse.containsKey('success'));
    }
    
    @isTest static void testUpdateErrorAccount() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Account';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"company_name" : "Salesoforce","customer_type_id" : null,"url" : "www.calenso.com","uuid" : null,"worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateAccount method
        AccountWebservice.updateAccount();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstAccountResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstAccountResponse.containsKey('error'));
    }
    
    @isTest static void testUpdateCompanyNameNullAccount() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Account';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"company_name" : null,"customer_type_id" : null,"url" : "www.calenso.com","uuid" : "WOS","worker_email" : "marvin.felder@calenso.com"}]');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateAccount method
        AccountWebservice.updateAccount();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        List<Object> responseBody = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.assertEquals(1, responseBody.size());
        Map<String,Object> firstAccountResponse = (Map<String,Object>)responseBody[0];
        System.assertEquals(true, firstAccountResponse.containsKey('error'));
    }
    
    @isTest static void testUpdateNoRecordPassed() {
      
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        // set request parameters
        request.requestURI = 'https://calenso-dev-ed.develop.my.salesforce.com/services/apexrest/Calenso/Account';
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('');
        // set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        // call the updateAccount method
        AccountWebservice.updateAccount();
        Test.stopTest();
        
        // assert the response
        System.assertEquals(400, response.statusCode);
        //System.assertEquals('application/json', response.getHeader('Content-Type'));
        Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
    	System.assertEquals('Invalid JSON Format.', responseBody.get('error'));
    }

}