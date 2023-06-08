/****************************************************************************************************
     * Create By : Dhruv Ladani
     * Create Date : 11-04-2023
     * Name : ActivityWebservice 
     * Modification Log:
     *  -------------------------------------------------------------------------------------------------
     *  * Developer                         Date                   Description
     *  *------------------------------------------------------------------------------------------------
     *  *  
     *  * Dhruv Ladani                      11-04-23                Initial 
*****************************************************************************************************/

@RestResource (urlMapping='/Activity/*')
global with sharing class ActivityWebservice {

    /****************************************************************************************************
     * Method Name :  createActivity
     * Create By : Dhruv Ladani
     * Create Date : 11-04-2023
     * Description : create Activity if customer_uuid is same as ExternalId in Lead or Contact records.
    ******************************************************************************************************/

    @HttpPost
    global static void createActivity(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String jsonPayload = req.requestBody.toString();

        List<User> checkuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

        Map<String,String> confirmusermap = new Map<String,String>();
        for (User validateowner : checkuser) {
            confirmusermap.put(validateowner.Email, validateowner.Id);
        }

        List<Event> activityList = new List<Event>();
        List<Map<String,Object>> errorList = new List<Map<String,Object>>();
        List<Object> requestObjectList = new List<Object>();

        try {
            List<Activity_Field_Mapping__mdt> mappings = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Activity_Field_Mapping__mdt WITH SECURITY_ENFORCED ];
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(jsonPayload);

            String sObjectApiName = 'Contact';
            String commaSeparatedFields = getCommaSeparatedFields(sObjectApiName);

            String sObjectApiName1 = 'Lead';
            String commaSeparatedFields1 = getCommaSeparatedFields(sObjectApiName1);

            List<String> uuidList = new List<String>();
            for (Object newuuid : dataList) {
                Map<String,Object> data = (Map<String,Object>) newuuid;
                uuidList.add((String) data.get('customer_uuid'));
            }

            String query = ' SELECT ' + commaSeparatedFields  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName + ' WHERE UUId__c = :uuidList';

            List<Contact> activity455 = Database.query(query);

            String queryLead = ' SELECT ' + commaSeparatedFields1  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName1 + ' WHERE UUId__c = :uuidList';

            List<Lead> activityLead = Database.query(queryLead);

            Map<String, Object> uuidToactivityIdMap = new Map<String, Object>();
            String uuidValue;
            for (Contact activity1 : activity455) {
                uuidValue = activity1.UUId__c;
                if (String.isNotBlank(uuidValue)) {
                    uuidToactivityIdMap.put(uuidValue, activity1.Id);
                }
            }
            for (Lead activity2 : activityLead) {
                uuidValue = activity2.UUId__c;
                if (String.isNotBlank(uuidValue)) {
                    uuidToactivityIdMap.put(uuidValue, activity2.Id);
                }
            }

            for (Object obj : dataList) {
                Map<String,Object> data = (Map<String,Object>) obj;
                String activityId = (String) data.get('uuid');
                String customer_uuid = (String) data.get('customer_uuid');

                if (uuidToactivityIdMap.containsKey(customer_uuid) && (data.get('uuid')) != null ) {
                    Event activity = new Event();
                    Boolean checkerror = true;

                    for (Activity_Field_Mapping__mdt fieldMap : mappings) {
                        Object jsonValue = data.get(fieldMap.JSON_Key__c);

                            if ((jsonValue != null || jsonValue == '') && DataTypeMapper.dataTypeToApexTypeMap.containsKey(fieldMap.Datatype__c)) {
                                Type fieldType = DataTypeMapper.dataTypeToApexTypeMap.get(fieldMap.Datatype__c);
                                if (fieldType == Decimal.class) {
                                    try {
                                        Decimal decimalValue = Decimal.valueOf(String.valueOf(jsonValue));
                                        activity.put(fieldMap.Field__c, decimalValue);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                } else if (fieldType == String.class) {
                                    try {
                                        if (fieldMap.JSON_Key__c == 'customer_uuid') {
                                            String uuidjsonvalue = String.valueOf(jsonValue);
                                            activity.put(fieldMap.Field__c, uuidjsonvalue);
                                            activity.put('WhoId', uuidToactivityIdMap.get(customer_uuid));
                                        }
                                        else if (fieldMap.JSON_Key__c == 'worker_email') {
                                            String ownerId = String.valueOf(jsonValue);
                                            if (confirmusermap.containsKey(ownerId)) {
                                                activity.put('OwnerId', confirmusermap.get(ownerId));
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
                                            activity.put(fieldMap.Field__c, String.valueOf(jsonValue));
                                        }                                
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }else if (fieldType == Date.class) {
                                    try {
                                        Date dateValue = Date.parse(String.valueOf(jsonValue));
                                        activity.put(fieldMap.Field__c, dateValue);
                                    }catch (TypeException e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }else if (fieldType == Datetime.class) {
                                    try {
                                        String dateTimeString = String.valueOf(jsonValue);
                                        String dateString = dateTimeString.substring(0, 10);
                                        String timeString = dateTimeString.substring(11, 19);
                                        Integer hour = Integer.valueOf(timeString.substring(0, 2));
                                        Integer minute = Integer.valueOf(timeString.substring(3, 5));
                                        Integer second = Integer.valueOf(timeString.substring(6, 8));
                                        Time startendTime = Time.newInstance(hour, minute, second, 0);
                                        Datetime startenddateTime = Datetime.newInstance(Date.valueOf(dateString), startendTime);
                                        activity.put(fieldMap.Field__c, startenddateTime);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                            }
                    }
                    if(checkerror){
                        activityList.add(activity);
                        requestObjectList.add(obj);
                    }
                }
                else {
                    data.put('id', String.valueOf(data.get('uuid')));
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    if (!uuidToactivityIdMap.containsKey(customer_uuid)) {
                        errorRecord.put('Error Message', 'Record not found with entered external id: ' + data.get('customer_uuid'));
                    }
                    else if (!uuidToactivityIdMap.containsKey(activityId)) {
                        errorRecord.put('Error Message', 'Uuid is null');                        
                    }
                    else if ((data.get('customer_uuid')) == null) {
                        errorRecord.put('Error Message', 'customer_uuid is null');                        
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

        Database.SaveResult[] srList = Database.insert(activityList, false);
        List<Object> finalResponse = ActivityObjectDataResponse(srList,activityList,errorList,requestObjectList);

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
     * Method Name :  updateActivity
     * Create By : Dhruv Ladani
     * Create Date : 13-04-2023
     * Description : update Activity if customer_uuid is same as ExternalId in Lead or Contact records and ExternalId of Activity records.
    ******************************************************************************************************/

    @HttpPatch
    global static void updateActivity(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String jsonPayload = req.requestBody.toString();

        List<User> checkuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

        Map<String,String> confirmusermap = new Map<String,String>();
        for (User validateowner : checkuser) {
            confirmusermap.put(validateowner.Email, validateowner.Id);
        }

        List<Event> activityList = new List<Event>();
        List<Map<String,Object>> errorList = new List<Map<String,Object>>();
        List<Object> requestObjectList = new List<Object>();

        try {
            List<Activity_Field_Mapping__mdt> mappings = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Activity_Field_Mapping__mdt WITH SECURITY_ENFORCED ];
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(jsonPayload);

            String sObjectApiName = 'Contact';
            String commaSeparatedFields = getCommaSeparatedFields(sObjectApiName);

            String sObjectApiName1 = 'Lead';
            String commaSeparatedFields1 = getCommaSeparatedFields(sObjectApiName1);

            List<String> uuidList = new List<String>();
            List<String> uuidList1 = new List<String>();
            for (Object newuuid : dataList) {
                Map<String,Object> data = (Map<String,Object>) newuuid;
                uuidList.add((String) data.get('customer_uuid'));
                uuidList1.add((String) data.get('uuid'));
            }

            String query = ' SELECT ' + commaSeparatedFields  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName + ' WHERE UUId__c = :uuidList';

            List<Contact> activity455 = Database.query(query);

            String queryLead = ' SELECT ' + commaSeparatedFields1  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName1 + ' WHERE UUId__c = :uuidList';

            List<Lead> activityLead = Database.query(queryLead);

            Map<String, Object> uuidToactivityIdMap = new Map<String, Object>();
            String uuidValue;
            for (Contact activity1 : activity455) {
                uuidValue = activity1.UUId__c;
                if (String.isNotBlank(uuidValue)) {
                    uuidToactivityIdMap.put(uuidValue, activity1.Id);
                }
            }
            for (Lead activity2 : activityLead) {
                uuidValue = activity2.UUId__c;
                if (String.isNotBlank(uuidValue)) {
                    uuidToactivityIdMap.put(uuidValue, activity2.Id);
                }
            }

            String sObjectApiName2 = 'Event';
            String commaSeparatedFields2 = getCommaSeparatedFields(sObjectApiName2);

            String queryEvent = ' SELECT ' + commaSeparatedFields2  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName2 + ' WHERE UUId__c = :uuidList1';
            List<Event> eventList = Database.query(queryEvent);

            Map<String, Id> uuidToeventIdMap = new Map<String, Id>();
            for (Event activity3 : eventList) {
                uuidValue = activity3.UUId__c;
                if (String.isNotBlank(uuidValue)) {
                    uuidToeventIdMap.put(uuidValue, activity3.Id);
                }
            }

            for (Object obj : dataList) {
                Map<String,Object> data = (Map<String,Object>) obj;
                String activityId = (String) data.get('uuid');
                String customer_uuid = (String) data.get('customer_uuid');

                if (uuidToactivityIdMap.containsKey(customer_uuid) && uuidToeventIdMap.containsKey(activityId) && data.get('uuid') != null && data.get('customer_uuid') != null) {
                    Event activity = new Event();
                    Boolean checkerror = true;

                    for (Activity_Field_Mapping__mdt fieldMap : mappings) {
                        Object jsonValue = data.get(fieldMap.JSON_Key__c);
                            if ((jsonValue != null || jsonValue == '') && DataTypeMapper.dataTypeToApexTypeMap.containsKey(fieldMap.Datatype__c)) {
                                Type fieldType = DataTypeMapper.dataTypeToApexTypeMap.get(fieldMap.Datatype__c);
                                if (fieldType == Decimal.class) {
                                    try {
                                        Decimal decimalValue = Decimal.valueOf(String.valueOf(jsonValue));
                                        activity.put(fieldMap.Field__c, decimalValue);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                } else if (fieldType == String.class) {
                                    try {
                                        if (fieldMap.JSON_Key__c == 'customer_uuid') {
                                            String uuidjsonvalue = String.valueOf(jsonValue);
                                            activity.put('WhoId', uuidToactivityIdMap.get(customer_uuid));
                                        }
                                        else if (fieldMap.JSON_Key__c == 'uuid') {
                                            activity.put('Id', uuidToeventIdMap.get(activityId));
                                        }
                                        else if (fieldMap.JSON_Key__c == 'worker_email') {
                                            String ownerId = String.valueOf(jsonValue);
                                            if (confirmusermap.containsKey(ownerId)) {
                                                activity.put('OwnerId', confirmusermap.get(ownerId));
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
                                            activity.put(fieldMap.Field__c, String.valueOf(jsonValue));
                                        }                                         
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }else if (fieldType == Date.class) {
                                    try {
                                        Date dateValue = Date.parse(String.valueOf(jsonValue));
                                        activity.put(fieldMap.Field__c, dateValue);
                                    }catch (TypeException e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                                else if (fieldType == Datetime.class) {
                                    try {
                                        String dateTimeString = String.valueOf(jsonValue);
                                        String dateString = dateTimeString.substring(0, 10);
                                        String timeString = dateTimeString.substring(11, 19);
                                        Integer hour = Integer.valueOf(timeString.substring(0, 2));
                                        Integer minute = Integer.valueOf(timeString.substring(3, 5));
                                        Integer second = Integer.valueOf(timeString.substring(6, 8));
                                        Time startendTime = Time.newInstance(hour, minute, second, 0);
                                        Datetime startenddateTime = Datetime.newInstance(Date.valueOf(dateString), startendTime);
                                        activity.put(fieldMap.Field__c, startenddateTime);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                            }
                    }if(checkerror){
                        activityList.add(activity);
                        requestObjectList.add(obj);
                    }
                }
                else {
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    if (!uuidToactivityIdMap.containsKey(customer_uuid)) {
                        errorRecord.put('Error Message', 'Record not found with entered external id: ' + data.get('customer_uuid'));
                    }
                    else if (!uuidToeventIdMap.containsKey(activityId)) {
                        errorRecord.put('Error Message', 'Record not found with entered external id: ' + data.get('uuid'));
                    }
                    else if ((data.get('customer_uuid')) == null) {
                        errorRecord.put('Error Message', 'customer_uuid is null');                        
                    }
                    else if ((data.get('uuid')) == null) {
                        errorRecord.put('Error Message', 'Uuid is null');                        
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

        Database.SaveResult[] srList = Database.update(activityList, false);
        List<Object> finalResponse = ActivityObjectDataResponse(srList,activityList,errorList,requestObjectList);

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
     * Method Name :  deleteActivity
     * Create By : Dhruv Ladani
     * Create Date : 17-04-2023
     * Description : delete Activity if same Activity ExternalId found in existing records.
    ******************************************************************************************************/

    @HttpDelete
    global static void deleteActivity(){
        System.RestRequest req = RestContext.request;
        System.RestResponse res = RestContext.response;
        String jsonPayload = req.requestBody.toString();

        List<User> checkuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

        Map<String,String> confirmusermap = new Map<String,String>();
        for (User validateowner : checkuser) {
            confirmusermap.put(validateowner.Email, validateowner.Id);
        }

        List<Event> activityList = new List<Event>();
        List<Map<String,Object>> errorList = new List<Map<String,Object>>();
        List<Object> requestObjectList = new List<Object>();
        Map<Id, String> eventIdTouuidMap = new Map<Id, String>();

        try {
            List<Activity_Field_Mapping__mdt> mappings = [SELECT Object__c, Field__c, JSON_Key__c, Datatype__c FROM Activity_Field_Mapping__mdt WITH SECURITY_ENFORCED ];
            List<Object> dataList = (List<Object>) JSON.deserializeUntyped(jsonPayload);

            List<String> uuidList = new List<String>();
            List<String> uuidList1 = new List<String>();
            for (Object newuuid : dataList) {
                Map<String,Object> data = (Map<String,Object>) newuuid;
                uuidList.add((String) data.get('customer_uuid'));
                uuidList1.add((String) data.get('uuid'));
            }

            Map<String, Object> uuidToactivityIdMap = new Map<String, Object>();
            String uuidValue;

            String sObjectApiName2 = 'Event';
            String commaSeparatedFields2 = getCommaSeparatedFields(sObjectApiName2);

            String queryEvent = ' SELECT ' + commaSeparatedFields2  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + SobjectApiName2 + ' WHERE UUId__c = :uuidList1';
            List<Event> eventList = Database.query(queryEvent);

            Map<String, Id> uuidToeventIdMap = new Map<String, Id>();
            for (Event activity3 : eventList) {
                uuidValue = activity3.UUId__c;
                if (String.isNotBlank(uuidValue)) {
                    uuidToeventIdMap.put(uuidValue, activity3.Id);
                    eventIdTouuidMap.put(activity3.Id, uuidValue);
                }
            }

            for (Object obj : dataList) {
                Map<String,Object> data = (Map<String,Object>) obj;
                String activityId = (String) data.get('uuid');
                String customer_uuid = (String) data.get('customer_uuid');

                if (data.get('uuid') != null  && uuidToeventIdMap.containsKey(activityId)) {
                    Event activity = new Event();
                    Boolean checkerror = true;

                    for (Activity_Field_Mapping__mdt fieldMap : mappings) {
                        Object jsonValue = data.get(fieldMap.JSON_Key__c);
                            if (jsonValue != null && DataTypeMapper.dataTypeToApexTypeMap.containsKey(fieldMap.Datatype__c)) {
                                Type fieldType = DataTypeMapper.dataTypeToApexTypeMap.get(fieldMap.Datatype__c);
                                if (fieldType == Decimal.class) {
                                    try {
                                        Decimal decimalValue = Decimal.valueOf(String.valueOf(jsonValue));
                                        activity.put(fieldMap.Field__c, decimalValue);
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                } else if (fieldType == String.class) {
                                    try {
                                        if (fieldMap.JSON_Key__c == 'uuid') {
                                            activity.put('Id', uuidToeventIdMap.get(activityId));
                                        }
                                        else if (fieldMap.JSON_Key__c == 'worker_email') {
                                            String ownerId = String.valueOf(jsonValue);
                                            if (confirmusermap.containsKey(ownerId)) {
                                                activity.put('OwnerId', confirmusermap.get(ownerId));
                                            }
                                        }
                                        else {
                                            activity.put(fieldMap.Field__c, String.valueOf(jsonValue));
                                        }                                         
                                    } catch (Exception e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                } else if (fieldType == Date.class) {
                                    try {
                                        Date dateValue = Date.parse(String.valueOf(jsonValue));
                                        activity.put(fieldMap.Field__c, dateValue);
                                    }catch (TypeException e) {
                                        checkerror = false;
                                        addErrorRecord(fieldMap, e, obj, errorList);
                                        continue;
                                    }
                                }
                            }
                    }if(checkerror){
                        activityList.add(activity);
                        requestObjectList.add(obj);
                    }
                }
                else {
                    Map<String,Object> errorRecord = new Map<String,Object>();
                    errorRecord.put('Error Message', 'Record not found with entered external uuid: ' + activityId + ' to delete');
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

        Database.DeleteResult[] srList = Database.delete(activityList, false);
        List<Object> finalResponse = ActivityObjectDeleteDataResponse(srList,eventIdTouuidMap,activityList,errorList,requestObjectList);

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
     * Method Name :  ActivityObjectDeleteDataResponse
     * Create By : Dhruv Ladani
     * Create Date : 17-04-2023
     * Description : handles succes and error records when deleting and display that records in response body.
    ******************************************************************************************************/

    public static List<Object> ActivityObjectDeleteDataResponse(List<Database.DeleteResult> saveResultData,Map<Id,String> activityidmapdata,List<Object> activityList,List<Object> errorList,List<Object> requestDataList){
        RestResponse response = RestContext.response;

        List<Id> activityListId = new List<Id>();  //store Activity ids
        List<Object> wrapperList = new List<Object>(); //sucess and error data list
        List<Object> errorListAfterInsert = new List<Object>(); // store error messages
        List<Object> successListAfterInsert = new List<Object>(); // store success messages

        List<Map<String,Object>> lstObj = new List<Map<String,Object>>();
        Integer indexValue = 0;

        //delete record created start
        Map<String,Object> resultMap = new Map<String,Object>();
        for(Database.DeleteResult singleSaveData : saveResultData) {
                if(singleSaveData.isSuccess()) {
                    activityListId.add(singleSaveData.getId());

                    List<Object> successMessageList = new List<Object>();
                    successMessageList.add('Record successfully deleted with ' + activityidmapdata.get(singleSaveData.getId()));

                    Map<String,Object> successMessageShow =  new Map<String,Object>();
                    successMessageShow.put('successMessage','Record successfully deleted with ' + activityidmapdata.get(singleSaveData.getId()));
                    successMessageShow.put('data',requestDataList.get(indexValue));
                    successListAfterInsert.add(successMessageList); 
                }else {
                    for(Database.Error err : singleSaveData.getErrors()) {
                        if(err.getMessage() != null){
                            Map<String,Object> errorMessageShow =  new Map<String,Object>();
                            errorMessageShow.put('errorMessage',err.getMessage());
                            errorMessageShow.put('data',requestDataList.get(indexValue));
                            errorListAfterInsert.add(errorMessageShow); 
                        } 
                    }
                }
                indexValue++;
        }
        
        if(activityListId.size()>0){
            if(successListAfterInsert.size()>0){
                for (Object successelse : successListAfterInsert) {
                    Map<String,Object> successJsonMap = new Map<String,Object>();
                    successJsonMap.put('error', null);
                    successJsonMap.put('success', successelse);
                    successJsonMap.put('status_code', '200');
                    if(successJsonMap != null){
                        lstObj.add(successJsonMap);
                    }
                }
            }
        }

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

    /****************************************************************************************************
     * Method Name :  addErrorRecord
     * Create By : Dhruv Ladani
     * Create Date : 13-04-2023
     * Description : add errorRecord that has Type Exception error into errorList.
    ******************************************************************************************************/

    private static void addErrorRecord(Activity_Field_Mapping__mdt fieldMap, Exception e, Object obj, List<Map<String,Object>> errorList) {
        Map<String,Object> errorRecord = new Map<String,Object>();
        errorRecord.put('Error Message', e.getMessage());
        errorRecord.put('errordata', obj);
        errorList.add(errorRecord);
    }

    /****************************************************************************************************
     * Method Name :  getCommaSeparatedFields
     * Create By : Dhruv Ladani
     * Create Date : 13-04-2023
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
     * Method Name :  ActivityObjectDataResponse
     * Create By : Dhruv Ladani
     * Create Date : 13-04-2023
     * Description : handles succes and error records and display that records in response body.
    ******************************************************************************************************/

    public static List<Object> ActivityObjectDataResponse(List<Database.SaveResult> saveResultData,List<Object> activityObjectData,List<Object> errorList,List<Object> requestDataList){
        
        RestResponse response = RestContext.response;

        List<Id> activityListId = new List<Id>();  //store Activity ids
        List<Object> wrapperList = new List<Object>(); //sucess and error data list
        List<Object> errorListAfterInsert = new List<Object>(); // store error messages
        
        List<Map<String,Object>> lstObj = new List<Map<String,Object>>();
        Integer indexValue = 0;

        //success record created start
        Map<String,Object> resultMap = new Map<String,Object>();
        for(Database.SaveResult singleSaveData : saveResultData) {
                if(singleSaveData.isSuccess()) {
                    activityListId.add(singleSaveData.getId());
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
        
        if(activityListId.size()>0){
            String sObjectApiName = 'Event';
            String commaSeparatedFields = getCommaSeparatedFields(sObjectApiName);

            String query = ' SELECT ' + commaSeparatedFields  + ',CreatedBy.Name,LastModifiedBy.Name FROM ' + sObjectApiName + ' WHERE Id = :activityListId';

            List<Event> activityListAfterInsert = Database.query(query);   

            List<Activity_Field_Mapping__mdt> mappingsafterinsert = [SELECT Field__c, JSON_Key__c, Datatype__c FROM Activity_Field_Mapping__mdt WITH SECURITY_ENFORCED  ];
            
            for (Event obj : activityListAfterInsert) {
                Map<String,Object> sucessJsonMap = new Map<String,Object>();
                Map<String,Object> fieldAandValueMap = new Map<String,Object>();

                List<User> newcheckuser = [SELECT Id,Name,Email from User WITH SECURITY_ENFORCED];

                Map<String,String> newconfirmusermap = new Map<String,String>();
                for (User validateowner : newcheckuser) {
                    newconfirmusermap.put(validateowner.Id, validateowner.Email);
                }
                
                for (Activity_Field_Mapping__mdt fieldMap : mappingsafterinsert) {
                    String fieldName = fieldMap.Field__c;

                    if (fieldName == 'OwnerId') {
                        fieldAandValueMap.put(fieldMap.JSON_Key__c, newconfirmusermap.get(obj.OwnerId));
                    }
                    else if (fieldName == 'WhoId') {
                        if(obj.WhoId != null && obj.WhoId.getSObjectType() == Lead.SObjectType){
                            Lead lead = [SELECT Id,Email,Phone FROM Lead WHERE Id = :obj.WhoId];
                            if (lead != null && lead.Phone != null && lead.Email != null) {
                                fieldAandValueMap.put('email', lead.Email);
                                fieldAandValueMap.put('mobile', lead.Phone);
                            }
                        }
                        else if(obj.WhoId != null && obj.WhoId.getSObjectType() == Contact.SObjectType){
                            Contact contact = [SELECT Id,Email,MobilePhone FROM Contact WHERE Id = :obj.WhoId];
                            if (contact != null && contact.MobilePhone != null && contact.Email != null) {
                                fieldAandValueMap.put('email', contact.Email);
                                fieldAandValueMap.put('mobile', contact.MobilePhone);
                            }
                        }
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