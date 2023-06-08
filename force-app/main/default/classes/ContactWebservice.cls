/****************************************************************************************************
     * Create By : Dhruv Ladani
     * Create Date : 05-04-2023
     * Name : ContactWebservice 
     * Modification Log:
     *  -------------------------------------------------------------------------------------------------
     *  * Developer                         Date                   Description
     *  *------------------------------------------------------------------------------------------------
     *  *  
     *  * Dhruv Ladani                      05-04-23                Initial 
*****************************************************************************************************/

@RestResource (urlMapping='/Contact/*')
global with sharing class ContactWebservice {

    /****************************************************************************************************
     * Method Name :  checkemailphone
     * Create By : Dhruv Ladani
     * Create Date : 05-04-2023
     * Description : checks email and phone in existing lead and contact records requested from payload.
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

        List<Contact> contactEmailPhoneList = [SELECT Id, Name, Email, OtherPhone FROM Contact WHERE Email = :emailList OR OtherPhone = :phoneList WITH SECURITY_ENFORCED];

        Set<String> emailSet = new Set<String>();
        Set<String> phoneSet = new Set<String>();
        Set<String> emailContactSet = new Set<String>();
        Set<String> phoneContactSet = new Set<String>();
        Map<String,String> leadexistingdatauuidwithsalesforceid = new Map<String,String>();
        Map<String,String> contactexistingdatauuidwithsalesforceid = new Map<String,String>();
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
        for (Contact contact : contactEmailPhoneList) {
            if (contact.Email != null) {
                emailContactSet.add(contact.Email);
                contactexistingdatauuidwithsalesforceid.put(requestdatawithemailuuidMap.get(contact.Email), contact.Id);
            }
            if (contact.OtherPhone != null) {
                phoneContactSet.add(contact.OtherPhone);
                contactexistingdatauuidwithsalesforceid.put(requestdatawithphoneuuidMap.get(contact.OtherPhone), contact.Id);
            }
        }
        Map<String,Object> emailphonemap = new Map<String,Object>();
        emailphonemap.put('emailmap', emailSet);
        emailphonemap.put('phonemap', phoneSet);
        emailphonemap.put('emailcontactmap', emailContactSet);
        emailphonemap.put('phonecontactmap', phoneContactSet);
        emailphonemap.put('existingleaddatamap', leadexistingdatauuidwithsalesforceid);
        emailphonemap.put('existingcontactdatamap', contactexistingdatauuidwithsalesforceid);
        return emailphonemap;
    }

    /****************************************************************************************************
     * Method Name :  createContact
     * Create By : Dhruv Ladani
     * Create Date : 05-04-2023
     * Description : create Contact if same email and phone not found in existing Lead and Contact records.
    ******************************************************************************************************/

    @HttpPost
    global static void createContact(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String jsonPayload = req.requestBody.toString();

        List<User> checkuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

        Map<String,String> confirmusermap = new Map<String,String>();
        for (User validateowner : checkuser) {
            confirmusermap.put(validateowner.Email, validateowner.Id);
        }

        List<Contact> contactList = new List<Contact>();
        List<Map<String,Object>> errorList = new List<Map<String,Object>>();
        List<Object> requestObjectList = new List<Object>();
        try {
            
            List<Contact_Field_Mapping__mdt> mappings = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Contact_Field_Mapping__mdt WITH SECURITY_ENFORCED ];
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(jsonPayload);
            Map<String,Object> existingContactEmailPhoneMap =  checkemailphone(dataList);
            Set<String> emailSet = (Set<String>)existingContactEmailPhoneMap.get('emailmap');
            Set<String> phoneSet = (Set<String>)existingContactEmailPhoneMap.get('phonemap');
            Set<String> emailContactSet = (Set<String>)existingContactEmailPhoneMap.get('emailcontactmap');
            Set<String> phoneContactSet = (Set<String>)existingContactEmailPhoneMap.get('phonecontactmap');
            Map<String,String> existingleaddatamap = (Map<String,String> )existingContactEmailPhoneMap.get('existingleaddatamap');
            Map<String,String> existingcontactdatamap = (Map<String,String> )existingContactEmailPhoneMap.get('existingcontactdatamap');
            
            for (Object obj : dataList) {
                Map<String,Object> data = (Map<String,Object>) obj;
                String emailMapValue = String.valueOf(data.get('email'));
                String phoneMapValue = String.valueOf(data.get('phone'));

                if (emailSet.contains(emailMapValue) || phoneSet.contains(phoneMapValue)) {
                    data.put('id', existingleaddatamap.get(String.valueOf(data.get('uuid'))));
                    List<Lead> leadsToUpdate = new List<Lead>();
                    Lead leadupdateuuid = new Lead();
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    errorRecord.put('Error Message', 'Lead Record already exists.');
                    errorRecord.put('errordata', data);
                    leadupdateuuid.Id = (String.valueOf(data.get('id')));
                    leadupdateuuid.UUId__c = (String.valueOf(data.get('uuid')));
                    leadsToUpdate.add(leadupdateuuid);
                    update leadsToUpdate;
                    errorList.add(errorRecord);
                    continue;
                }
                else if(emailContactSet.contains(emailMapValue) || phoneContactSet.contains(phoneMapValue)){
                    data.put('id', existingcontactdatamap.get(String.valueOf(data.get('uuid'))));
                    List<Contact> contactToUpdate = new List<Contact>();
                    Contact contactupdateuuid = new Contact();
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    errorRecord.put('Error Message', 'Contact Record already exists.');
                    errorRecord.put('errordata', data);
                    contactupdateuuid.Id = (String.valueOf(data.get('id')));
                    contactupdateuuid.UUId__c = (String.valueOf(data.get('uuid')));
                    contactToUpdate.add(contactupdateuuid);
                    update contactToUpdate;
                    errorList.add(errorRecord);
                    continue;
                }
                else if(String.valueOf(data.get('uuid')) != null){
                    Contact contact = new Contact();
                    Boolean checkerror = true;
                    for (Contact_Field_Mapping__mdt fieldMap : mappings) {
                        Object jsonValue = data.get(fieldMap.JSON_Key__c);
                            
                            if (jsonValue != null && DataTypeMapper.dataTypeToApexTypeMap.containsKey(fieldMap.Datatype__c)) {
                                Type fieldType = DataTypeMapper.dataTypeToApexTypeMap.get(fieldMap.Datatype__c);
                                if (fieldType == Decimal.class) {
                                    try {
                                        Decimal decimalValue = Decimal.valueOf(String.valueOf(jsonValue));
                                        contact.put(fieldMap.Field__c, decimalValue);
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
                                                contact.put('OwnerId', confirmusermap.get(ownerId));
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
                                            contact.put(fieldMap.Field__c, String.valueOf(jsonValue));
                                        }
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }else if (fieldType == Date.class) {
                                    try {
                                        String dateString = String.valueOf(jsonValue);
                                        Pattern datePattern = Pattern.compile('^\\d{4}-\\d{2}-\\d{2}$'); // Define regex pattern for yyyy-mm-dd format
                                        Matcher matcher = datePattern.matcher(dateString);
                                        if (matcher.matches()) {
                                            Date dateValue = Date.valueOf(dateString);
                                            contact.put(fieldMap.Field__c, dateValue);    
                                        } else {
                                            checkerror = false;
                                            Map<String,Object> err= new Map<String,Object>();
                                            err.put('getMessage', 'Please enter the valid format YYYY-MM-DD');
                                            addErrorRecord(fieldMap, err, obj, errorList);
                                            continue;
                                        }
                                    }catch (TypeException e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                            }
                    }if(checkerror){
                        contactList.add(contact);
                        requestObjectList.add(obj);
                    }
                }else {
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    if (String.valueOf(data.get('uuid')) == null) {
                        errorRecord.put('Error Message', 'Uuid is null');
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

        Database.SaveResult[] srList = Database.insert(contactList, false);
        List<Object> finalResponse = ContactObjectDataResponse(srList,contactList,errorList,requestObjectList);

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
     * Method Name :  updateContact
     * Create By : Dhruv Ladani
     * Create Date : 07-04-2023
     * Description : update Contact if same ExternalId found in existing contact records.
    ******************************************************************************************************/

    @HttpPatch
    global static void updateContact(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String jsonPayload = req.requestBody.toString();

        List<User> checkuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

        Map<String,String> confirmusermap = new Map<String,String>();
        for (User validateowner : checkuser) {
            confirmusermap.put(validateowner.Email, validateowner.Id);
        }

        List<Contact> contactList = new List<Contact>();
        List<Map<String,Object>> errorList = new List<Map<String,Object>>();
        List<Object> requestObjectList = new List<Object>();

        try {
            List<Contact_Field_Mapping__mdt> mappings = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Contact_Field_Mapping__mdt WITH SECURITY_ENFORCED ];
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(jsonPayload);
            
            String sObjectApiName = 'Contact';
            String commaSeparatedFields = getCommaSeparatedFields(sObjectApiName);

            List<String> uuidList = new List<String>();
            for (Object newuuid : dataList) {
                Map<String,Object> data = (Map<String,Object>) newuuid;
                uuidList.add(String.valueOf(data.get('uuid')));
            }
            String query = ' SELECT ' + commaSeparatedFields  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName + ' WHERE UUId__c = :uuidList';
            List<Contact> contact45 = Database.query(query);
            Map<String, Id> uuidTocontactIdMap = new Map<String, Id>();
            String uuidValue;
            for (Contact contact1 : contact45) {
                uuidValue = contact1.UUId__c;
                if (String.isNotBlank(uuidValue)) {
                    uuidTocontactIdMap.put(uuidValue, contact1.Id);
                }
            }

            for (Object obj : dataList) {
                Map<String,Object> data = (Map<String,Object>) obj;
                String contactId = String.valueOf(data.get('uuid'));

                if (uuidTocontactIdMap.containsKey(contactId) && String.valueOf(data.get('uuid')) != null) {
                    Contact contact = new Contact();
                    Boolean checkerror = true;
                    for (Contact_Field_Mapping__mdt fieldMap : mappings) {
                        Object jsonValue = data.get(fieldMap.JSON_Key__c);
                            if ((jsonValue != null || jsonValue == '') && DataTypeMapper.dataTypeToApexTypeMap.containsKey(fieldMap.Datatype__c)) {
                                Type fieldType = DataTypeMapper.dataTypeToApexTypeMap.get(fieldMap.Datatype__c);
                                if (fieldType == Decimal.class) {
                                    try {
                                        Decimal decimalValue = Decimal.valueOf(String.valueOf(jsonValue));
                                        contact.put(fieldMap.Field__c, decimalValue);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                } else if (fieldType == String.class) {
                                    try {
                                        if (fieldMap.JSON_Key__c == 'uuid') {
                                            String uuidjsonvalue = String.valueOf(jsonValue);
                                            contact.put(fieldMap.Field__c, uuidjsonvalue);
                                            contact.put('Id', uuidTocontactIdMap.get(contactId));
                                        }
                                        else if (fieldMap.JSON_Key__c == 'worker_email') {
                                            String ownerId = String.valueOf(jsonValue);
                                            if (confirmusermap.containsKey(ownerId)) {
                                                contact.put('OwnerId', confirmusermap.get(ownerId));
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
                                            contact.put(fieldMap.Field__c, String.valueOf(jsonValue));
                                        }
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }else if (fieldType == Date.class) {
                                    try {
                                        String dateString = String.valueOf(jsonValue);
                                        Pattern datePattern = Pattern.compile('^\\d{4}-\\d{2}-\\d{2}$'); // Define regex pattern for yyyy-mm-dd format
                                        Matcher matcher = datePattern.matcher(dateString);
                                        if (matcher.matches()) {
                                            Date dateValue = Date.valueOf(dateString);
                                            contact.put(fieldMap.Field__c, dateValue);    
                                        } else {
                                            checkerror = false;
                                            Map<String,Object> err= new Map<String,Object>();
                                            err.put('getMessage', 'Please enter the valid format YYYY-MM-DD');
                                            addErrorRecord(fieldMap, err, obj, errorList);
                                            continue;
                                        }
                                    }catch (TypeException e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                            }
                    }if(checkerror){
                        contactList.add(contact);
                        requestObjectList.add(obj);
                    }
                }
                else {
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    if (data.get('uuid') == null) {
                        errorRecord.put('Error Message', 'Uuid is null');
                    }else {
                        errorRecord.put('Error Message', 'Record not found with entered external id: ' + contactId);
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

        Database.SaveResult[] srList = Database.update(contactList, false);
        List<Object> finalResponse = ContactObjectDataResponse(srList,contactList,errorList,requestObjectList);

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
     * Method Name :  addErrorRecord
     * Create By : Dhruv Ladani
     * Create Date : 07-04-2023
     * Description : add errorRecord that has Type Exception error into errorList.
    ******************************************************************************************************/

    private static void addErrorRecord(Contact_Field_Mapping__mdt fieldMap, Object e, Object obj, List<Map<String,Object>> errorList) {
        if (e instanceof Exception) {
            Exception ex = (Exception) e;
            Map<String,Object> errorRecord = new Map<String,Object>();
            errorRecord.put('Error Message', ex.getMessage());
            errorRecord.put('errordata', obj);
            errorList.add(errorRecord);
        } else if (e instanceof Map<String,Object>) {
            Map<String,Object> ex = (Map<String,Object>) e;
            Map<String,Object> errorRecord = new Map<String,Object>();
            errorRecord.put('Error Message', ex.get('getMessage'));
            errorRecord.put('errordata', obj);
            errorList.add(errorRecord);
        }
    }

    /****************************************************************************************************
     * Method Name :  getCommaSeparatedFields
     * Create By : Dhruv Ladani
     * Create Date : 07-04-2023
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
     * Method Name :  ContactObjectDataResponse
     * Create By : Dhruv Ladani
     * Create Date : 07-04-2023
     * Description : handles succes and error records and display that records in response body.
    ******************************************************************************************************/

    public static List<Object> ContactObjectDataResponse(List<Database.SaveResult> saveResultData,List<Object> contactObjectData,List<Object> errorList,List<Object> requestDataList){
        
        RestResponse response = RestContext.response;
        List<Id> contactListId = new List<Id>();  //store account ids
        List<Object> errorListAfterInsert = new List<Object>(); // store error messages

        List<Map<String,Object>> lstObj = new List<Map<String,Object>>();
        Integer indexValue = 0;

        //success record created start
        Map<String,Object> resultMap = new Map<String,Object>();
        for(Database.SaveResult singleSaveData : saveResultData) {
                if(singleSaveData.isSuccess()) {
                    contactListId.add(singleSaveData.getId());
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
        
        if(contactListId.size()>0){
            String sObjectApiName = 'Contact';
            String commaSeparatedFields = getCommaSeparatedFields(sObjectApiName);

            String query = ' SELECT ' + commaSeparatedFields  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName + ' WHERE Id = :contactListId';

            List<Contact> contactListAfterInsert = Database.query(query);   

            List<Contact_Field_Mapping__mdt> mappingsafterinsert = [SELECT Field__c, JSON_Key__c, Datatype__c FROM Contact_Field_Mapping__mdt WITH SECURITY_ENFORCED  ];
            
            for (Contact obj : contactListAfterInsert) {
                Map<String,Object> sucessJsonMap = new Map<String,Object>();
                Map<String,Object> fieldAandValueMap = new Map<String,Object>();
                
                List<User> newcheckuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

                Map<String,String> newconfirmusermap = new Map<String,String>();
                for (User validateowner : newcheckuser) {
                        newconfirmusermap.put(validateowner.Id, validateowner.Email);
                }
                
                for (Contact_Field_Mapping__mdt fieldMap : mappingsafterinsert) {
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