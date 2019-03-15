/* @createdBy Saquib
 * @description [NPI-558] This controller will be used for BuyBoard, Publishing Plan and Publishing Template
 * @createdDate 20/Nov/2018
   //V1.1 - Modified By - Anna Sinha - 30/11/2018 -- BuyBoard Creation
 */
//Naman Code optimization 14/03/19
public class BB_PlanController {

    @AuraEnabled
    public static BodyData planDetails(String planId, Boolean isCLone) {
        BodyData bd = new BodyData();
        try {
            Plan__c planRec = new Plan__c();
            bd.isSuccess = true;
            if(isCLone){
                planRec = getPlanList(new List<String> {planId}).get(0).clone(false, false, false, false);
                planRec.Name = '';
            } else {
                planRec = getPlanList(new List<String> {planId}).get(0);
            }
            bd.plan = planRec;
            User urec = [SELECT IsPortalEnabled FROM User WHERE Id =: UserInfo.getUserId() limit 1];
            bd.isPortalUser = urec.IsPortalEnabled;
        }
        catch(Exception ex) {
            bd.isSuccess = false;
            bd.strMessage = ex.getMessage();
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_PlanController,Method - planDetails', ex.getLineNumber() + ' - ' + ex.getMessage());         
        }
        return bd; 
    }

    @AuraEnabled
    public static LoginUserDetails getUserDetail() {
        LoginUserDetails response = new LoginUserDetails();
        try {
            response.accountIds = new List<String>();
            Set<String> setAccountNumber = new Set<String>();
            User urec = [SELECT Id, AccountId,Account.Name, IsPortalEnabled, ContactId,Contact.AccountId  FROM User WHERE Id =: UserInfo.getUserId() limit 1];
            response.isPortalUser = urec.IsPortalEnabled;

            // To show only Primary Account of Community User.
            if(response.isPortalUser) {
                 response.accountIds.add(urec.AccountId);
                 /* NPI-3892 Allowing agent on behalf of License
                    @Naman Start
                 */
                /*if(urec.Contact.AccountId != null){
                    
                    list<Contractspd__c> Contractspd = BB_PlanHelperController.getContarcts(urec.Contact.AccountId);
                    
                    if(Contractspd.size() > 0){
                        response.isPortalUser = false;
                        for(Contractspd__c con:Contractspd) {
                            response.accountIds.add(con.Licensee__c);
                        }
                    } 
                }*/
                /* NPI-3892 END commented by naman jain 08/03/19
                */
            } else {
                //For Internal Users
                List<contractspd__c> contractPds = [select id,licensee_key__c,agent_key__c, Licensee__c from contractspd__c where Licensee__c != NULL AND End_Date__c >: Date.today()];
                for(contractspd__c con : contractPds) {
                    response.accountIds.add(con.Licensee__c);
                }
            }
        }
        catch(Exception ex) {
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_PlanController,Method - getUserDetail', ex.getLineNumber() + ' - ' + ex.getMessage());         
        }
        return response;
    }

    static Set<String> checkProperties( Plan__c newPlanRec) {
        try {
            List<Plan__c> plans = [SELECT Properties__c FROM Plan__c WHERE Parent__c = : newPlanRec.Id];
            Set<String> errorSet = new Set<String>();
            String properties = newPlanRec.Properties__c;
            //@Naman 27/02/19 NPI-558 code optimzation Start
            Set<String> planProperties = new Set<String>(newPlanRec.Properties__c.split(';'));
            for(Plan__c p : plans) {
                Set<String> tempSet = new Set<String>(planProperties);
                Set<String> childSet = new Set<String>(p.Properties__c.split(';'));
                if(!tempSet.containsAll(childSet)) {
                    childSet.removeAll(tempSet);
                    errorSet.addAll(childSet);
                }
            }
            //@Naman 27/02/19 NPI-558 code optimzation End

            return errorSet;
        }
        catch(Exception ex) {
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_PlanController,Method - checkProperties', ex.getLineNumber() + ' - ' + ex.getMessage());    
            return null;     
        }
        
    }
    @AuraEnabled
    public static BodyData creatNewBBPlan(String planRec){
        BodyData bd = new BodyData();
        try {
            bd.isSuccess = true;
            Plan__c newPlanRec = (Plan__c)JSON.deserialize(planRec, Plan__c.class);
            newPlanRec.RecordTypeId = BuyBoard_Constants.PLAN_BUY_BOARD_RECORD_TYPE_ID;
            if(!String.isEmpty(newPlanRec.Id)) {
                Set<String> errorSet = checkProperties(newPlanRec);
                if(!errorSet.isEmpty()) {
                    bd.isSuccess = false;
                    bd.strMessage = System.Label.PD_Deselect_Property_Error + ' ' + String.join(new List<String>(errorSet), '; ');
                    return bd;
                }
            }
            //@Naman NPI-3665 28/02/19 Start
            Contractspd__c contract;
            List<String> planProperties = newPlanRec.Properties__c.split(';');
            //Naman code optimization 14/03/19 Start
            List<Contractspd__c> contractList = BB_PlanHelperController.getContarct( newPlanRec.Account__c);
            //Naman code optimization 14/03/19 End
            List<Contractspd__c> finalContracts = new List<Contractspd__c>();
            finalContracts.addAll(contractList);
            for(Contractspd__c con : contractList) {
                //Naman Jain NPI-3892 06/03/19 Start
                if(!String.isEmpty(con.Properties_lt__c) && !String.isEmpty(con.Product_Hierarchy__c)) {
                //Naman Jain NPI-3892 06/03/19 End
                    Set<String> conProperties = new Set<String>(con.Properties_lt__c.split(';'));
                    conProperties.retainAll(planProperties);
                    if(conProperties.size() == planProperties.size()) {
                        contract = con;
                        break;
                    }
                }
            }
            if(contract != null) {
                newPlanRec.Plan_Category__c = BB_PlanHelperController.getCategory(contract.Product_Hierarchy__c);
            }
            //@Naman NPI-3665 28/02/19 End

            //@Naman NPI-558 Code optimizing 14/03/19 Start 
            BuyBoard_PlanWrapper.ResponseBaseWrapper res = BB_PlanHelperController.insertPlan(newPlanRec);
            if(!res.isSuccess) {
                bd.isSuccess = false;
                bd.strMessage = res.strMessage;
            }
            //@Naman NPI-558 Code optimizing 14/03/19 END 
            bd.plan = newPlanRec;
        }
        catch(Exception ex) {
            bd.isSuccess = false;
            bd.strMessage = ex.getMessage();            
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_PlanController,Method - createNewBBPlan', ex.getLineNumber() + ' - ' + ex.getMessage());  
        }
        return bd;
    }

    public static List<Plan__c> getPlanList(List<String> listIds) {
        List<Plan__c> planList = new List<Plan__c>();
        try {
            planList = [SELECT Id, Name, CreatedBy.Name, Reviewer__c, Properties__c , 
                                Reviewer__r.Name, Account__c, Account__r.Name, Description__c 
                                FROM Plan__c 
                                WHERE Id IN : listIds];
        }
        catch(Exception ex) {
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_PlanController,Method - getPlanList', ex.getLineNumber() + ' - ' + ex.getMessage());  
        }
        return planList;
    }

    @AuraEnabled
    public static ContractsData fetchAccountDetails(String strAccountId) {
        ContractsData response = new ContractsData();
        response.isSuccess = true;
        Set<String> setOfProperties = new Set<String>();
        try {
            if(String.isNotBlank(strAccountId)) {
                response.listContracts = BB_PlanHelperController.getContarct(strAccountId);
                if(!response.listContracts.isEmpty()) {
                    for(Contractspd__c cp : response.listContracts) {
                        if(cp.Properties_lt__c != null) {
                            setOfProperties.addALL(cp.Properties_lt__c.split(';'));
                        }
                        // Updated by Anna Sinha for NPI-558 defect 20thfeb2019
                        /*if(cp.Product_Hierarchy__c != null) {
                            response.categories = cp.Product_Hierarchy__c;
                        }*///Comented by Naman Jain 
                        // Updated by Anna Sinha for NPI-558 defect 20thfeb2019
                    }
                    for(String str : setOfProperties) {
                        response.listOfPlanProperties.add(new planPropertyData(str,false));
                    }
                    response.listOfPlanProperties.sort();
                }                         
            }
            else {
                response.isSuccess = false;
                response.strMessage = System.Label.PD_Licensee_Error;
            }
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_PlanController,Method - fetchAccountDetails', ex.getLineNumber() + ' - ' + ex.getMessage());  
        }
        return response;
    }
    
    /**
     * @description     :   This method is used to get base details for object. Like: Fields to display, Records
     *
     *  @args           :   String, String, String
     *
     *  @return         :   BaseData
     *
     *  @revision Log   :   V1.0 - Created - 11/22/2018 - Saquib
     *                      V1.1 - Modified - 11/22/2018 - Subhash Garwal - continue work on method
     * 
     **/
    @AuraEnabled
    public static BaseData getBaseConfig1(String strSelObject, String currentUserId, String listViewTypeName) {
        
        //Instance of the Basedata class
        BaseData response = new BaseData();
        response.isSuccess = true;
        
        //Check for Object and Current user
        if(String.isNotBlank(strSelObject) && String.isNotBlank(currentUserId)) {
            
            //List View wrappe to get data result
            ListViewWrapper.BaseData listViewData = new ListViewWrapper.BaseData(); 
            
            try {
                
                //Set current user
                if(String.isBlank(currentUserId))
                    currentUserId = [SELECT Id, Name, UserType, Profile.Name, Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1].Id;
                //Naman Jain Code Optimization 13/03/19 Start
                //Get current user type
                string currentUserType = PD_ListViewHelper.getUserType(UserInfo.getUserId());
                
                //Populate field details
                listViewData.sObjectWrap = PD_ListViewHelper.getObjectDetails(strSelObject);
                listViewData.listFields = PD_ListViewHelper.listAllSelFields(strSelObject, currentUserType);
                listViewData.mapFields = PD_ListViewHelper.listAllFields(strSelObject);
                //Naman Jain Code Optimization 13/03/19 End
                listViewData.strUserType = currentUserType;
                
                //Loop over the field to get selected fields
                for(String strField : listViewData.listFields)
                    listViewData.mapSelFields.put(strField, listViewData.mapFields.get(strField));
                
                //Get record of the Plan
                listViewData.listRecords = fetchPlanRecords(strSelObject, listViewData.mapSelFields, currentUserId, listViewTypeName);
            
                //Add Table headers
                response.listTableHeader.add(new HeaderData('Image', false, 'firsrowcolor'));
                
                //Check list of fields
                if(listViewData.listFields != null) {
                    
                    // Create Table Header set for init JQuery Datatable
                    for( String strFieldName : listViewData.listFields) {            
                        
                        //Check if field need to include
                        if(listViewData.mapSelFields != null && listViewData.mapSelFields.containsKey(strFieldName) && listViewData.mapSelFields.get(strFieldName) != null)     
                            response.listTableHeader.add(new HeaderData(listViewData.mapSelFields.get(strFieldName).strLabel, true, 'firsrowcolor'));
                    }   
                }
                
                
                //Loop over the record to add in list
                for(sObject record : listViewData.listRecords) {
                    
                    //Temp variable to pass the Plan data in list
                    List<String> listRowData = new List<String>();
                    
                    //Check if URL is not null
                    if(record.get('Main_File_URL__c') != null)
                        listRowData.add('<img class=\'sentImage\'  src=\''+ String.valueOf(record.get('Main_File_URL__c'))+'\'/>');
                    else
                        listRowData.add('');          
                        
                    //Loop over the fields
                    for( String strFieldName : listViewData.listFields ) { 
                        
                        //Check for image field
                        if(String.isNotBlank(strFieldName) && ( strFieldName.equalsIgnoreCase('Name'))) {
                            listRowData.add('<a target=\'_blank\' href=\'/' + String.valueOf(record.get('Id')) + '\'>' + String.valueOf(record.get(strFieldName)) + '</a>');        
                        
                        } else if(listViewData.mapSelFields.containsKey(strFieldName) && listViewData.mapSelFields.get(strFieldName) != null
                            && listViewData.mapSelFields.get(strFieldName).strType.toUpperCase() == 'REFERENCE' && record.getSobject(listViewData.mapSelFields.get(strFieldName).strRelationshipName) != null) {
                            listRowData.add(String.valueOf(record.getSobject(listViewData.mapSelFields.get(strFieldName).strRelationshipName).get('Name')));                    
                        } else if(record.get(strFieldName) != NULL) {
                            listRowData.add(String.valueOf(record.get(strFieldName)));                  
                        } else {
                            listRowData.add('');
                        }
                    }
                    response.listTableData.add(listRowData);
                }
            } catch(Exception ex) {
                response.isSuccess = false;
                response.strMessage = ex.getMessage();
                PD_utilityClass.ErrorHandling( 'Apexclass - BB_PlanController,Method - getBaseConfig1', ex.getLineNumber() + ' - ' + ex.getMessage());  
            }
        }
        
        return response;
    }
    
    /**
     * @description     :   This method is used to get base details of object and provide all records avilable for Plan Object
     *
     *  @args           :   String, Map<String, ListViewWrapper.SFieldWrapper> mapSelFields, String, String
     *
     *  @return         :   BaseData
     *
     *  @revision Log   :   V1.0 - Created - 11/28/2018 - Subhash Garwal
     *                      
     * 
     **/

    public static List<Sobject> fetchPlanRecords(String strSelObject, Map<String, ListViewWrapper.SFieldWrapper> mapSelFields, String currentUserId, String listViewTypeName) {
        //List of Sobject
        List<Sobject> objectRecords = new List<Sobject>();
        try {
            //Check for object
            if(String.isNotBlank(strSelObject)) {
                
                //Build SOQL query
                String SOQLQuery = 'Select ';
                
                //Loop over the fields
                for(String strFieldName : mapSelFields.keySet()) {
                    
                    SOQLQuery += strFieldName + ',';
                    
                    //Check if field is refrence type
                    if(mapSelFields.containsKey(strFieldName) && mapSelFields.get(strFieldName) != null && mapSelFields.get(strFieldName).strType.toUpperCase() == System.Label.PD_REFERENCE_Caps)
                        SOQLQuery += mapSelFields.get(strFieldName).strRelationshipName + '.Name,';
                }
                
                //Add object details
                SOQLQuery = SOQLQuery.removeEnd(',') + ', Main_File_URL__c FROM ' + strSelObject + ' Where RecordTypeId = \'' + BuyBoard_Constants.PLAN_BUY_BOARD_RECORD_TYPE_ID + '\' ';
                
                //Check for listview Type
                if(String.isNotBlank(listViewTypeName) && listViewTypeName != System.Label.PD_All)
                    SOQLQuery += 'AND Plan_Type__c =\'' + listViewTypeName + '\' AND Sent_To__c =\'' + UserInfo.getUserId() + '\'';
                
                //Remove additional char from String
                SOQLQuery = SOQLQuery.removeEnd(' Where ');
                
                //Check for SOQL String
                if(String.isNotBlank(SOQLQuery))
                    objectRecords = Database.query(SOQLQuery);  
            }
        }
        catch(Exception ex) {
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_PlanController,Method - fetchPlanRecords', ex.getLineNumber() + ' - ' + ex.getMessage());  
        }
    return objectRecords;
    }

    /**
     *  @description sObject Field Wrapper
     */
    public virtual class ResponseBase {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String strMessage;
    }
    
    public class ContractsData extends ResponseBase {
        @AuraEnabled public List<Contractspd__c> listContracts;
        @AuraEnabled public List<planPropertyData> listOfPlanProperties;
       // @AuraEnabled public String categories; commented by Naman Jain 28/02/19
        public ContractsData() {
            this.listOfPlanProperties = new List<planPropertyData>();
        }
    }

     public class planPropertyData implements Comparable {
        @AuraEnabled public String properties;
        @AuraEnabled public Boolean isSelected;
        public planPropertyData(String properties, Boolean isSelected) {
            this.properties = properties;
            this.isSelected = isSelected;
        }
        public Integer compareTo(Object objToCompare) {
            return properties.compareTo(((planPropertyData)objToCompare).properties);
    	}
    }
    // @Naman NPI-558 14/02/19 Start
    public class LoginUserDetails extends ResponseBase {
    // @Naman NPI-558 14/02/19 End
        @AuraEnabled public Boolean isPortalUser {get;set;}
        @AuraEnabled public List<String> accountIds {get;set;}
        @AuraEnabled public String accountName {get;set;}
    }
    
    //Base Data class
    public class BaseData extends ResponseBase {
       
        @AuraEnabled public List<HeaderData> listTableHeader {get; set;}
        @AuraEnabled public List<List<String>> listTableData {get; set;}
        @AuraEnabled public String strUserType {get; set;}
        
        public BaseData() {
            this.listTableHeader = new List<HeaderData>();
            this.listTableData = new List<List<String>>();
        }
    }
    
    //Header row class
    public class HeaderData {
        @AuraEnabled public String title {get; set;}
        @AuraEnabled public Boolean orderable {get; set;}
        @AuraEnabled public String strClass {get; set;}
        
        public HeaderData(String title, Boolean orderable, String strClass) {
            this.title = title;
            this.orderable = orderable;
            this.strClass = strClass;
        }
    }
    public class BodyData extends ResponseBase{
        @AuraEnabled public Plan__c plan {get;set;}
        @AuraEnabled public Boolean isPortalUser {get;set;}

    }
}