/****************************************************************************************************
     * Create By : Dhruv Ladani
     * Create Date : 30-03-2023
     * Name : AccountWebservice 
     * Modification Log:
     *  -------------------------------------------------------------------------------------------------
     *  * Developer                         Date                   Description
     *  *------------------------------------------------------------------------------------------------
     *  *  
     *  * Dhruv Ladani                      30-03-23                Initial 
*****************************************************************************************************/

@RestResource (urlMapping='/Account/*')
global with sharing class AccountWebservice {

    /****************************************************************************************************
     * Method Name :  checkname
     * Create By : Dhruv Ladani
     * Create Date : 30-03-2023
     * Description : checks company name in existing account records requested from payload.
    ******************************************************************************************************/

    public static Map<String,Object> checkname(List<Object> oldObject) {
        List<String> nameList = new List<String>();
        Map<String,String> requestdatawithnameuuidMap = new Map<String,String>();

        for (Object singleobj : oldObject) {
            Map<String,Object> data = (Map<String,Object>) singleobj;
            if (account.Name != null) {
                nameList.add(String.valueOf(data.get('company_name')));
                requestdatawithnameuuidMap.put(String.valueOf(data.get('company_name')), String.valueOf(data.get('uuid')));
            }
        }

        List<Account> accountNameList = [SELECT Id, Name FROM Account WHERE Name = :nameList WITH SECURITY_ENFORCED];

        Set<String> nameSet = new Set<String>();
        Map<String,String> accountexistingdatauuidwithsalesforceid = new Map<String,String>();

        for(Account account : accountNameList){
            if (account.Name != null) {
                nameSet.add(account.Name);
                accountexistingdatauuidwithsalesforceid.put(requestdatawithnameuuidMap.get(account.Name), account.Id);
            }
        }

        Map<String,Object> accountNameMap = new Map<String,Object>();
        accountNameMap.put('namemap', nameSet);
        accountNameMap.put('existingaccountdatamap', accountexistingdatauuidwithsalesforceid);
        return accountNameMap;
    }

    /****************************************************************************************************
     * Method Name :  createAccount
     * Create By : Dhruv Ladani
     * Create Date : 30-03-2023
     * Description : create Account if same company name not found in existing records.
    ******************************************************************************************************/

    @HttpPost
    global static void createAccount(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String jsonPayload = req.requestBody.toString();

        List<User> checkuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

        Map<String,String> confirmusermap = new Map<String,String>();
        for (User validateowner : checkuser) {
            confirmusermap.put(validateowner.Email, validateowner.Id);
        }

        List<Account> accountList = new List<Account>();
        List<Map<String,Object>> errorList = new List<Map<String,Object>>();
        List<Object> requestObjectList = new List<Object>();
        try {
            
            List<Account_Field_Mapping__mdt> mappings = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Account_Field_Mapping__mdt WITH SECURITY_ENFORCED ];
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(jsonPayload);

            Map<String,Object> existingAccountNameMap =  checkname(dataList);
            Set<String> nameSet = (Set<String>)existingAccountNameMap.get('namemap');
            Map<String,String> existingaccountdatamap = (Map<String,String> )existingAccountNameMap.get('existingaccountdatamap');
            
            for (Object obj : dataList) {
                Map<String,Object> data = (Map<String,Object>) obj;
                String nameMapValue = String.valueOf(data.get('company_name'));

                if (!nameSet.contains(nameMapValue) && data.get('uuid') !=null && data.get('company_name') !=null) {
                    Account account = new Account();
                    Boolean checkerror = true;

                    for (Account_Field_Mapping__mdt fieldMap : mappings) {
                        Object jsonValue = data.get(fieldMap.JSON_Key__c);
                        
                            if (jsonValue != null && DataTypeMapper.dataTypeToApexTypeMap.containsKey(fieldMap.Datatype__c)) {
                                Type fieldType = DataTypeMapper.dataTypeToApexTypeMap.get(fieldMap.Datatype__c);
                                if (fieldType == Decimal.class) {
                                    try {
                                        Decimal decimalValue = Decimal.valueOf(String.valueOf(jsonValue));
                                        account.put(fieldMap.Field__c, decimalValue);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                } else if (fieldType == String.class) {
                                    try {
                                        if (fieldMap.JSON_Key__c == 'worker_email') {
                                            String ownerId = String.valueOf(jsonValue);
                                            if (confirmusermap.containsKey(ownerId)) {
                                                account.put('OwnerId', confirmusermap.get(ownerId));
                                            }
                                            else {
                                                Boolean userExists = false;
                                                for (User user : checkuser) {
                                                    if (user.Email == ownerId) {
                                                        userExists = true;
                                                        break;
                                                    }
                                                }
                                                if (!userExists) {
                                                    throw new JSONException('User not found with the entered worker email');
                                                }
                                            }
                                        }
                                        else {
                                            account.put(fieldMap.Field__c, String.valueOf(jsonValue));
                                        }                                
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }else if (fieldType == Date.class) {
                                    try {
                                        Date dateValue = Date.parse(String.valueOf(jsonValue));
                                        account.put(fieldMap.Field__c, dateValue);
                                    }catch (TypeException e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                            }
                    }if(checkerror){
                        accountList.add(account);
                        requestObjectList.add(obj);
                    }
                }
                else {
                    data.put('id', existingaccountdatamap.get(String.valueOf(data.get('uuid'))));
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    if (data.get('uuid') == null) {
                        errorRecord.put('Error Message', 'Uuid is null');
                    }else if(data.get('company_name') == null){
                        errorRecord.put('Error Message', 'Company Name is null');
                    }else {
                        errorRecord.put('Error Message', 'Record already exists.');
                        List<Account> accountToUpdate = new List<Account>();
                        Account accountupdateuuid = new Account();
                        accountupdateuuid.Id = (String.valueOf(data.get('id')));
                        accountupdateuuid.UUId__c = (String.valueOf(data.get('uuid')));
                        accountToUpdate.add(accountupdateuuid);
                        update accountToUpdate;
                    }
                    errorRecord.put('errordata', data);
                    errorList.add(errorRecord);
                    continue;
                }
            }
        } catch (JSONException e) {
            res.statusCode = 400; // Internal Server Error
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'error' => 'Invalid JSON Format.',
                'status_code' => '400'
            }));
            return;
        }

        Database.SaveResult[] srList = Database.insert(accountList, false);
        List<Object> finalResponse = AccountObjectDataResponse(srList,accountList,errorList,requestObjectList);

        // response send to requested body
        Boolean checksuccess = false;
        for (Object newmap : finalResponse) {
            Map<String,Object> newsinglemap = (Map<String,Object>)newmap;
            if (newsinglemap.get('success') != null) {
                checksuccess = true;
                break;
            }
        }
        if (checksuccess) {
            res.statusCode = 200;
        }
        else {
            res.statusCode = 400;
        }
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(finalResponse)); 
    }

    /****************************************************************************************************
     * Method Name :  updateAccount
     * Create By : Dhruv Ladani
     * Create Date : 03-04-2023
     * Description : update Account if same ExternalId found in existing records.
    ******************************************************************************************************/

    @HttpPatch
    global static void updateAccount(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String jsonPayload = req.requestBody.toString();

        List<User> checkuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

        Map<String,String> confirmusermap = new Map<String,String>();
        for (User validateowner : checkuser) {
            confirmusermap.put(validateowner.Email, validateowner.Id);
        }

        List<Account> accountList = new List<Account>();
        List<Map<String,Object>> errorList = new List<Map<String,Object>>();
        List<Object> requestObjectList = new List<Object>();

        try {
            List<Account_Field_Mapping__mdt> mappings = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Account_Field_Mapping__mdt WITH SECURITY_ENFORCED ];
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(jsonPayload);
            
            String sObjectApiName = 'Account';
            String commaSeparatedFields = getCommaSeparatedFields(sObjectApiName);

            List<String> uuidList = new List<String>();
            for (Object newuuid : dataList) {
                Map<String,Object> data = (Map<String,Object>) newuuid;
                uuidList.add((String.valueOf(data.get('uuid'))));
            }

            String query = ' SELECT ' + commaSeparatedFields  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName + ' WHERE UUId__c = :uuidList';

            List<Account> account45 = Database.query(query);

            Map<String, Id> uuidToAccountIdMap = new Map<String, Id>();
            String uuidValue;
            for (Account account1 : account45) {
                uuidValue = account1.UUId__c;
                if (String.isNotBlank(uuidValue)) {
                    uuidToAccountIdMap.put(uuidValue, account1.Id);
                }
            }

            for (Object obj : dataList) {
                Map<String,Object> data = (Map<String,Object>) obj;
                String accountId = (String.valueOf(data.get('uuid')));

                if (uuidToAccountIdMap.containsKey(accountId) && data.get('uuid') !=null && data.get('company_name') !=null) {
                    Account account = new Account();
                    Boolean checkerror = true;

                    for (Account_Field_Mapping__mdt fieldMap : mappings) {
                        Object jsonValue = data.get(fieldMap.JSON_Key__c);

                            if ((jsonValue != null || jsonValue == '') && DataTypeMapper.dataTypeToApexTypeMap.containsKey(fieldMap.Datatype__c)) {
                                Type fieldType = DataTypeMapper.dataTypeToApexTypeMap.get(fieldMap.Datatype__c);
                                if (fieldType == Decimal.class) {
                                    try {
                                        Decimal decimalValue = Decimal.valueOf(String.valueOf(jsonValue));
                                        account.put(fieldMap.Field__c, decimalValue);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                } else if (fieldType == String.class) {
                                    try {
                                        if (fieldMap.JSON_Key__c == 'uuid') {
                                            String uuidjsonvalue = String.valueOf(jsonValue);
                                                account.put(fieldMap.Field__c, uuidjsonvalue);
                                                account.put('Id', uuidToAccountIdMap.get(accountId));
                                        }                              
                                        else if (fieldMap.JSON_Key__c == 'worker_email') {
                                            String ownerId = String.valueOf(jsonValue);
                                            if (confirmusermap.containsKey(ownerId)) {
                                                account.put('OwnerId', confirmusermap.get(ownerId));
                                            }
                                            else {
                                                Boolean userExists = false;
                                                for (User user : checkuser) {
                                                    if (user.Email == ownerId) {
                                                        userExists = true;
                                                        break;
                                                    }
                                                }
                                                if (!userExists) {
                                                    throw new JSONException('User not found with the entered worker email');
                                                }
                                            }
                                        }
                                        else {
                                            account.put(fieldMap.Field__c, String.valueOf(jsonValue));
                                        }                                
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }else if (fieldType == Date.class) {
                                    try {
                                        Date dateValue = Date.parse(String.valueOf(jsonValue));
                                        account.put(fieldMap.Field__c, dateValue);
                                    }catch (TypeException e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                            }
                    }if(checkerror){
                        accountList.add(account);
                        requestObjectList.add(obj);
                    }
                }
                else {
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    if (data.get('uuid') == null) {
                        errorRecord.put('Error Message', 'Uuid is null');
                    }else if(data.get('company_name') == null){
                        errorRecord.put('Error Message', 'Company Name is null');
                    }else {
                        errorRecord.put('Error Message', 'Record not found with entered external id: ' + accountId);
                    }
                    errorRecord.put('errordata', obj);
                    errorList.add(errorRecord);
                    continue;
                }
            }
        } catch (JSONException e) {
            res.statusCode = 400; // Internal Server Error
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'error' => 'Invalid JSON Format.',
                'status_code' => '400'
            }));
            return;
        }

        Database.SaveResult[] srList = Database.update(accountList, false);
        List<Object> finalResponse = AccountObjectDataResponse(srList,accountList,errorList,requestObjectList);

        Boolean checksuccess = false;
        for (Object newmap : finalResponse) {
            Map<String,Object> newsinglemap = (Map<String,Object>)newmap;
            if (newsinglemap.get('success') != null) {
                checksuccess = true;
                break;
            }
        }
        if (checksuccess) {
            res.statusCode = 200;
        }
        else {
            res.statusCode = 400;
        }
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(finalResponse)); 
    }

    /****************************************************************************************************
     * Method Name :  addErrorRecord
     * Create By : Dhruv Ladani
     * Create Date : 03-04-2023
     * Description : add errorRecord that has Type Exception error into errorList.
    ******************************************************************************************************/

    private static void addErrorRecord(Account_Field_Mapping__mdt fieldMap, Exception e, Object obj, List<Map<String,Object>> errorList) {
        Map<String,Object> errorRecord = new Map<String,Object>();
        errorRecord.put('Error Message', e.getMessage());
        errorRecord.put('errordata', obj);
        errorList.add(errorRecord);
    }

    /****************************************************************************************************
     * Method Name :  getCommaSeparatedFields
     * Create By : Dhruv Ladani
     * Create Date : 03-04-2023
     * Description : seperate fields from object in dynamic query.
    ******************************************************************************************************/

    public static String getCommaSeparatedFields(String objectApiName) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objectApiName).getDescribe().fields.getMap();
        String commaSeparatedFields = '';
        for (String fieldName : fieldMap.keySet()) {
            if (commaSeparatedFields == null || commaSeparatedFields == '') {
                commaSeparatedFields = fieldName;
            } else {
                commaSeparatedFields += ', ' + fieldName;
            }
        }
        return commaSeparatedFields;
    }

    /****************************************************************************************************
     * Method Name :  AccountObjectDataResponse
     * Create By : Dhruv Ladani
     * Create Date : 03-04-2023
     * Description : handles succes and error records and display that records in response body.
    ******************************************************************************************************/

    public static List<Object> AccountObjectDataResponse(List<Database.SaveResult> saveResultData,List<Object> accountObjectData,List<Object> errorList,List<Object> requestDataList){
        
        RestResponse response = RestContext.response;
        List<Id> accountListId = new List<Id>();  //store account ids
        List<Object> errorListAfterInsert = new List<Object>(); // store error messages

        List<Map<String,Object>> lstObj = new List<Map<String,Object>>();
        Integer indexValue = 0;

        //success record created start
        Map<String,Object> resultMap = new Map<String,Object>();
        for(Database.SaveResult singleSaveData : saveResultData) {
                if(singleSaveData.isSuccess()) {
                    accountListId.add(singleSaveData.getId());
                }else {
                    for(Database.Error err : singleSaveData.getErrors()) {
                        if(err.getMessage() != null){
                            Map<String,Object> errorMessageShow =  new Map<String,Object>();
                            if (err.getMessage().contains('duplicate value found: Calenso__UUId__c duplicates value on record')) {
                                    Map<String, Object> record = (Map<String, Object>) requestDataList.get(indexValue);
                                    String getuuid = (String) record.get('uuid');
                                    errorMessageShow.put('errorMessage', 'ExternalId duplicates value on record with uuid: ' + getuuid);
                            }
                            else {
                                errorMessageShow.put('errorMessage',err.getMessage());
                            }
                            errorMessageShow.put('data',requestDataList.get(indexValue));
                            errorListAfterInsert.add(errorMessageShow); 
                        } 
                    }
                }
                indexValue++;
        }
        
        if(accountListId.size()>0){
            String sObjectApiName = 'Account';
            String commaSeparatedFields = getCommaSeparatedFields(sObjectApiName);

            String query = ' SELECT ' + commaSeparatedFields  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName + ' WHERE Id = :accountListId';

            List<Account> accountListAfterInsert = Database.query(query);   

            List<Account_Field_Mapping__mdt> mappingsafterinsert = [SELECT Field__c, JSON_Key__c, Datatype__c FROM Account_Field_Mapping__mdt WITH SECURITY_ENFORCED  ];
            
            for (Account obj : accountListAfterInsert) {
                Map<String,Object> sucessJsonMap = new Map<String,Object>();
                Map<String,Object> fieldAandValueMap = new Map<String,Object>();

                List<User> newcheckuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

                Map<String,String> newconfirmusermap = new Map<String,String>();
                for (User validateowner : newcheckuser) {
                    newconfirmusermap.put(validateowner.Id, validateowner.Email);
                }
                
                for (Account_Field_Mapping__mdt fieldMap : mappingsafterinsert) {
                    String fieldName = fieldMap.Field__c;
                    if (fieldName == 'OwnerId') {
                        fieldAandValueMap.put(fieldMap.JSON_Key__c, newconfirmusermap.get(obj.OwnerId));
                    }
                    else {
                        fieldAandValueMap.put(fieldMap.JSON_Key__c, obj.get(fieldName));
                    }                    
                }
                sucessJsonMap.put('success', fieldAandValueMap);
                sucessJsonMap.put('id',obj.Id);
                sucessJsonMap.put('error', null);
                sucessJsonMap.put('status_code', '200');
                lstObj.add(sucessJsonMap);    
            }
        }
        //success record created end

        //error Data type block Start
        for(Object errordata: errorList){
            Map<String,object> errorDetailMap = (Map<String,object>)errordata;
            String errorMessage = (String)errorDetailMap.get('Error Message');
            Map<String,Object> bodyData = (Map<String,Object>)errorDetailMap.get('errordata');
            Map<String,Object> errorMessageShow =  new Map<String,Object>();
            errorMessageShow.put('errorMessage',errorMessage);
            errorMessageShow.put('data',bodyData);
            if(errorMessageShow != null){
                errorListAfterInsert.add(errorMessageShow);
            }
        }
        //error Data type block End

        if(errorListAfterInsert.size()>0){
            for (Object errorelse : errorListAfterInsert) {
                Map<String,Object> errorJsonMap = new Map<String,Object>();
                errorJsonMap.put('error', errorelse);
                errorJsonMap.put('success', null);
                errorJsonMap.put('status_code', '401');
                if(errorJsonMap != null){
                    lstObj.add(errorJsonMap);
                }
            }
        }
        //errrorrecord in databse end
        return lstObj;  
    }
}