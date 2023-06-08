/****************************************************************************************************
     * Create By : Dhruv Ladani
     * Create Date : 24-03-2023
     * Name : LeadWebservice 
     * Modification Log:
     *  -------------------------------------------------------------------------------------------------
     *  * Developer                         Date                   Description
     *  *------------------------------------------------------------------------------------------------
     *  *  
     *  * Dhruv Ladani                      24-03-23                Initial 
*****************************************************************************************************/

@RestResource (urlMapping='/Lead/*')
global with sharing class LeadWebservice {

    /****************************************************************************************************
     * Method Name :  checkemailphone
     * Create By : Dhruv Ladani
     * Create Date : 24-03-2023
     * Description : checks email and phone in existing lead records requested from payload.
    ******************************************************************************************************/

    public static Map<String,Object> checkemailphone(List<Object> oldObject) {
        List<String> emailList = new List<String>();
        List<String> phoneList = new List<String>();
        Map<String,String> requestdatawithemailuuidMap = new Map<String,String>();
        Map<String,String> requestdatawithphoneuuidMap = new Map<String,String>();

        for (Object singleobj : oldObject) {
            Map<String,Object> data = (Map<String,Object>) singleobj;
            if (lead.Email != null) {
                emailList.add(String.valueOf(data.get('email')));
                requestdatawithemailuuidMap.put(String.valueOf(data.get('email')), String.valueOf(data.get('uuid')));
            }
            if (lead.Phone != null) {
                phoneList.add(String.valueOf(data.get('phone')));
                requestdatawithphoneuuidMap.put(String.valueOf(data.get('phone')), String.valueOf(data.get('uuid')));
            }
        }

        List<Lead> emailphoneList = [SELECT Id, Name, Email, Phone FROM Lead WHERE (Email = :emailList OR Phone = :phoneList) AND Status !='Closed - Converted' AND Status !='Closed - Not Converted' WITH SECURITY_ENFORCED];

        Set<String> emailSet = new Set<String>();
        Set<String> phoneSet = new Set<String>();
        Map<String,String> leadexistingdatauuidwithsalesforceid = new Map<String,String>();

        for(Lead lead : emailphoneList){
            if (lead.Email != null) {
                emailSet.add(lead.Email);
                leadexistingdatauuidwithsalesforceid.put(requestdatawithemailuuidMap.get(lead.Email), lead.Id);
            }
            if (lead.Phone != null) {
                phoneSet.add(lead.Phone);
                leadexistingdatauuidwithsalesforceid.put(requestdatawithphoneuuidMap.get(lead.Phone), lead.Id);
            }
        }

        Map<String,Object> emailphonemap = new Map<String,Object>();
        emailphonemap.put('emailmap', emailSet);
        emailphonemap.put('phonemap', phoneSet);
        emailphonemap.put('existingleaddatamap', leadexistingdatauuidwithsalesforceid);
        return emailphonemap;
    }

    /****************************************************************************************************
     * Method Name :  createLead
     * Create By : Dhruv Ladani
     * Create Date : 24-03-2023
     * Description : create Lead if same email and phone not found in existing records.
    ******************************************************************************************************/

    @HttpPost
    global static void createLead(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String jsonPayload = req.requestBody.toString();

        List<User> checkuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

        Map<String,String> confirmusermap = new Map<String,String>();
        for (User validateowner : checkuser) {
            confirmusermap.put(validateowner.Email, validateowner.Id);
        }

        List<Lead> leadList = new List<Lead>();
        List<Map<String,Object>> errorList = new List<Map<String,Object>>();
        List<Object> requestObjectList = new List<Object>();

        try {
            List<Lead_Field_Mapping__mdt> mappings = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Lead_Field_Mapping__mdt WITH SECURITY_ENFORCED ];
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(jsonPayload);

            Map<String,Object> existingLeadEmailPhoneMap =  checkemailphone(dataList);

            Set<String> emailSet = (Set<String>)existingLeadEmailPhoneMap.get('emailmap');
            Set<String> phoneSet = (Set<String>)existingLeadEmailPhoneMap.get('phonemap');
            Map<String,String> existingleaddatamap = (Map<String,String> )existingLeadEmailPhoneMap.get('existingleaddatamap');

            for (Object obj : dataList) {
                Map<String,Object> data = (Map<String,Object>) obj;
                String emailMapValue = String.valueOf(data.get('email'));
                String phoneMapValue = String.valueOf(data.get('phone'));

                if ((!emailSet.contains(emailMapValue) && !phoneSet.contains(phoneMapValue)) && data.get('uuid') !=null ) {
                    Lead lead = new Lead();
                    Boolean checkerror = true;

                    for (Lead_Field_Mapping__mdt fieldMap : mappings) {
                        Object jsonValue = data.get(fieldMap.JSON_Key__c);

                            if (jsonValue != null && DataTypeMapper.dataTypeToApexTypeMap.containsKey(fieldMap.Datatype__c)) {
                                Type fieldType = DataTypeMapper.dataTypeToApexTypeMap.get(fieldMap.Datatype__c);
                                if (fieldType == Decimal.class) {
                                    try {
                                        Decimal decimalValue = Decimal.valueOf(String.valueOf(jsonValue));
                                        lead.put(fieldMap.Field__c, decimalValue);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                } 
                                else if (fieldType == String.class) {
                                    try {
                                        if (fieldMap.JSON_Key__c == 'worker_email') {
                                            String ownerId = String.valueOf(jsonValue);
                                            if (confirmusermap.containsKey(ownerId)) {
                                                lead.put('OwnerId', confirmusermap.get(ownerId));
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
                                            lead.put(fieldMap.Field__c, String.valueOf(jsonValue));
                                        }                                
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                                else if (fieldType == Date.class) {
                                    try {
                                        Date dateValue = Date.parse(String.valueOf(jsonValue));
                                        lead.put(fieldMap.Field__c, dateValue);
                                    }catch (TypeException e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                            }
                    }
                    if(checkerror){
                        leadList.add(lead);
                        requestObjectList.add(obj);
                    }
                }
                else {
                    data.put('id', existingleaddatamap.get(String.valueOf(data.get('uuid'))));
                    Map<String,Object> errorRecord = new Map<String,Object>();

                    if (data.get('uuid') == null) {
                        errorRecord.put('Error Message', 'Uuid is null');
                    }else {
                        errorRecord.put('Error Message', 'Record already exists.');
                        List<Lead> leadsToUpdate = new List<Lead>();
                        Lead leadupdateuuid = new Lead();
                        leadupdateuuid.Id = (String.valueOf(data.get('id')));
                        leadupdateuuid.UUId__c = (String.valueOf(data.get('uuid')));
                        leadsToUpdate.add(leadupdateuuid);
                        update leadsToUpdate;
                    }
                    errorRecord.put('errordata', data);
                    errorList.add(errorRecord);
                    continue;
                }
            }
        } catch (Exception e) {
            res.statusCode = 400; // Internal Server Error
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'error' => 'Invalid JSON Format.',
                'status_code' => '400'
            }));
            return;
        }

        Database.SaveResult[] srList = Database.insert(leadList, false);
        List<Object> finalResponse = leadObjectDataResponse(srList,leadList,errorList,requestObjectList);

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
     * Method Name :  updateLead
     * Create By : Dhruv Ladani
     * Create Date : 28-03-2023
     * Description : update Lead if same ExternalId found in existing records.
    ******************************************************************************************************/

    @HttpPatch
    global static void updateLead(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String jsonPayload = req.requestBody.toString();

        List<User> checkuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

        Map<String,String> confirmusermap = new Map<String,String>();
        for (User validateowner : checkuser) {
            confirmusermap.put(validateowner.Email, validateowner.Id);
        }

        List<Lead> leadList = new List<Lead>();
        List<Map<String,Object>> errorList = new List<Map<String,Object>>();
        List<Object> requestObjectList = new List<Object>();

        try {
            List<Lead_Field_Mapping__mdt> mappings = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Lead_Field_Mapping__mdt WITH SECURITY_ENFORCED ];
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(jsonPayload);

            String sObjectApiName = 'Lead';
            String commaSeparatedFields = getCommaSeparatedFields(sObjectApiName);

            List<String> uuidList = new List<String>();
            for (Object newuuid : dataList) {
                Map<String,Object> data = (Map<String,Object>) newuuid;
                uuidList.add((String.valueOf(data.get('uuid'))));
            }

            String query = ' SELECT ' + commaSeparatedFields  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName + ' WHERE UUId__c = :uuidList';

            List<Lead> lead45 = Database.query(query);

            Map<String, Id> uuidToLeadIdMap = new Map<String, Id>();
            String uuidValue;
            for (Lead lead1 : lead45) {
                uuidValue = lead1.UUId__c;
                if (String.isNotBlank(uuidValue)) {
                    uuidToLeadIdMap.put(uuidValue, lead1.Id);
                }
            }

            for (Object obj : dataList) {
                Map<String,Object> data = (Map<String,Object>) obj;
                String leadId = (String.valueOf(data.get('uuid')));

                if (uuidToLeadIdMap.containsKey(leadId) && String.valueOf(data.get('uuid')) !=null) {
                    Lead lead = new Lead();
                    Boolean checkerror = true;

                    for (Lead_Field_Mapping__mdt fieldMap : mappings) {
                        Object jsonValue = data.get(fieldMap.JSON_Key__c);

                            if ((jsonValue != null || jsonValue == '') && DataTypeMapper.dataTypeToApexTypeMap.containsKey(fieldMap.Datatype__c)) {
                                Type fieldType = DataTypeMapper.dataTypeToApexTypeMap.get(fieldMap.Datatype__c);
                                if (fieldType == Decimal.class) {
                                    try {
                                        Decimal decimalValue = Decimal.valueOf(String.valueOf(jsonValue));
                                        lead.put(fieldMap.Field__c, decimalValue);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                } else if (fieldType == String.class) {
                                    try {
                                        if (fieldMap.JSON_Key__c == 'uuid') {
                                            String uuidjsonvalue = String.valueOf(jsonValue);
                                                lead.put(fieldMap.Field__c, uuidjsonvalue);
                                                lead.put('Id', uuidToLeadIdMap.get(leadId));
                                        }
                                        else if (fieldMap.JSON_Key__c == 'worker_email') {
                                            String ownerId = String.valueOf(jsonValue);
                                            if (confirmusermap.containsKey(ownerId)) {
                                                lead.put('OwnerId', confirmusermap.get(ownerId));
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
                                            lead.put(fieldMap.Field__c, String.valueOf(jsonValue));
                                        }                                         
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }else if (fieldType == Date.class) {
                                    try {
                                        Date dateValue = Date.parse(String.valueOf(jsonValue));
                                        lead.put(fieldMap.Field__c, dateValue);
                                    }catch (TypeException e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                            }
                    }if(checkerror){
                        leadList.add(lead);
                        requestObjectList.add(obj);
                    }
                }
                else {
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    if (data.get('uuid') == null) {
                        errorRecord.put('Error Message', 'Uuid is null');
                    }else {
                        errorRecord.put('Error Message', 'Record not found with entered external id: ' + leadId);
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

        Database.SaveResult[] srList = Database.update(leadList, false);
        List<Object> finalResponse = leadObjectDataResponse(srList,leadList,errorList,requestObjectList);

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
     * Create Date : 28-03-2023
     * Description : add errorRecord that has Type Exception error into errorList.
    ******************************************************************************************************/

    public static void addErrorRecord(Lead_Field_Mapping__mdt fieldMap, Exception e, Object obj, List<Map<String,Object>> errorList) {
        Map<String,Object> errorRecord = new Map<String,Object>();
        errorRecord.put('Error Message', e.getMessage());
        errorRecord.put('errordata', obj);
        errorList.add(errorRecord);
    }

    /****************************************************************************************************
     * Method Name :  getCommaSeparatedFields
     * Create By : Dhruv Ladani
     * Create Date : 28-03-2023
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
     * Method Name :  leadObjectDataResponse
     * Create By : Dhruv Ladani
     * Create Date : 28-03-2023
     * Description : handles succes and error records and display that records in response body.
    ******************************************************************************************************/

    public static List<Object> leadObjectDataResponse(List<Database.SaveResult> saveResultData,List<Object> leadObjectData,List<Object> errorList,List<Object> requestDataList){
        
        RestResponse response = RestContext.response;

        List<Id> leadListId = new List<Id>();  //store lead ids
        List<Object> wrapperList = new List<Object>(); //sucess and error data list
        List<Object> errorListAfterInsert = new List<Object>(); // store error messages
        
        List<Map<String,Object>> lstObj = new List<Map<String,Object>>();
        Integer indexValue = 0;

        //success record created start
        Map<String,Object> resultMap = new Map<String,Object>();
        for(Database.SaveResult singleSaveData : saveResultData) {
                if(singleSaveData.isSuccess()) {
                    leadListId.add(singleSaveData.getId());
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
        
        if(leadListId.size()>0){
            String sObjectApiName = 'Lead';
            String commaSeparatedFields = getCommaSeparatedFields(sObjectApiName);

            String query = ' SELECT ' + commaSeparatedFields  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName + ' WHERE Id = :leadListId';

            List<Lead> leadListAfterInsert = Database.query(query);   

            List<Lead_Field_Mapping__mdt> mappingsafterinsert = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Lead_Field_Mapping__mdt WITH SECURITY_ENFORCED  ];
            
            for (Lead obj : leadListAfterInsert) {
                Map<String,Object> sucessJsonMap = new Map<String,Object>();
                Map<String,Object> fieldAandValueMap = new Map<String,Object>();
                
                List<User> newcheckuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

                Map<String,String> newconfirmusermap = new Map<String,String>();
                for (User validateowner : newcheckuser) {
                        newconfirmusermap.put(validateowner.Id, validateowner.Email);
                }
                
                for (Lead_Field_Mapping__mdt fieldMap : mappingsafterinsert) {
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

        //error Data type block Start which shows error message on response body
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