/**
 *  @author Tushar Kumawat
 *  @date 28 April 2018
 *  @description Helper controller for Agent approval scenario
 */
public class AgentApprovalHelper {
    public static List<String> LIST_AGENT_PROFILES = new List<String> {'Agent'};
	public static List<String> LIST_LICENSEE_PROFILES = new List<String> {'Licensees'};
	public static List<String> LIST_CREATIVE_LOB_PROFILES = new List<String> {'Creative_LOB', 'Creative Users', 'System Administrator', 'LOB users', 'PD Admins'};
    public static List<String> LIST_CREATIVE_PROFILES = new List<String> {'Creative Users'};
    public static List<String> LIST_LOB_PROFILES = new List<String> {'Creative_LOB', 'LOB users'};
    
	/**
     *  @description returns current user's profile details
     */
    public static UserProfileWrap getProfileDetails(String strUserId) {
        UserProfileWrap response = new UserProfileWrap();
        response.isSuccess = true;
        
        try {
            User currUser = [SELECT Id, Name, ProfileId, Profile.Name FROM User WHERE Id =: strUserId];
            response.strProfileId = currUser.ProfileId;
            response.strProfileName = currUser.Profile.Name;
            response.strUserType = UserInfo.getUserType();
            
            if(LIST_AGENT_PROFILES.contains(currUser.Profile.Name)) {
                response.isAgentUser = true;
            }
            else if(LIST_LICENSEE_PROFILES.contains(currUser.Profile.Name)) {
                response.isLicenseeUser = true;
            }
            else if(LIST_CREATIVE_LOB_PROFILES.contains(currUser.Profile.Name)) {
                response.isCreativeLobUser = true;
            }
            
            if(response.strUserType.equals('Standard')) {
                response.isInternalUser = true;
            }
            else {
                response.isInternalUser = false;
            }
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }
        
        return response;
    }
    
    /**
     *  @description returns current user's profile details
     */
    public static ComponentWrap getComponentDetails(String strComponentId, UserProfileWrap userProfile, Boolean doSkipProfile) {
        ComponentWrap response = new ComponentWrap();
        response.isAgentApprovable = false;
        response.isSuccess = true;
        response.currentUser = userProfile;
        
        try {
            Component__c currComponent = ApprovalBaseHelper.getComponentList(new List<String> {strComponentId}).get(0);
            response.currComponent = currComponent;
            List<String> listAllStages = new List<String>();
            Set<String> setSkippedStages;
            
            if(String.isNotBlank(currComponent.Component_Status__c)) {
                if(currComponent.Component_Status__c.equalsIgnoreCase('Rejected')) {
                    response.isRejected = true;
                }
            }
            
            if([SELECT count() FROM sharinpix__SharinPixImage__c WHERE Component_Formula__c =: strComponentId] > 0) {
                response.imagePresent = true;
            }
            
            if(currComponent != NULL && String.isNotBlank(currComponent.Skipped_Stages__c)) {
                setSkippedStages = new Set<String>(currComponent.Skipped_Stages__c.split(','));
            }  
            else {
                setSkippedStages = new Set<String>();
            }
            
            if(String.isNotBlank(currComponent.Addition_Stage__c)) {
                listAllStages = currComponent.Addition_Stage__c.split(';');
                Integer intStageNumber = 0;
                String strComponentStatus = '';
                
                if(currComponent.Stage_Number__c != NULL) {
                    intStageNumber = Integer.valueOf(currComponent.Stage_Number__c);
                }
                
                if(String.isNotBlank(currComponent.Component_Status__c)) {
                    strComponentStatus = currComponent.Component_Status__c;
                }
                system.debug('current status'+strComponentStatus );
                for(Integer index = 0; index < listAllStages.size(); index++) {
                    if(index < intStageNumber || strComponentStatus.equalsIgnoreCase('Completed')) { 
                        response.listApprovedStages.add(new StageWrap(listAllStages[index], setSkippedStages.contains(listAllStages[index])));
                    }
                    else if(index == intStageNumber) {
                        response.listCurrentStages.add(listAllStages[index]);
                    }
                    else {
                        response.listFutureStages.add(listAllStages[index]);
                    }
                }
            }
            
            response.currentStageRounds = Integer.valueOf( currComponent.Round__c != NULL ? currComponent.Round__c : 0 );
            response.strComponentId = currComponent.id;
            response.strRecordTypeId = currComponent.RecordTypeId;
            response.strRecordTypeName = currComponent.RecordType.Name;            
            response.strComponentStatus = currComponent.Component_Status__c;
            response.isLocked = Approval.isLocked(strComponentId);
            response.isProduction = response.listCurrentStages.contains('Production');
            response.isPreProduction = response.listCurrentStages.contains('Pre-Production');
            
            List<String> listAgentKeys = new List<String>();
            
            for(Contractspd__c contractPSD : [SELECT agent_key__c FROM Contractspd__c WHERE Contract_Id__c =: currComponent.Submission__r.Contractnumber__c]) {
                if(String.isNotBlank(contractPSD.agent_key__c)) {
                    listAgentKeys.add(contractPSD.agent_key__c);
                }
            }
            System.debug('listAgentKeys ::: ' + listAgentKeys);
            for(Account currAccount : [SELECT Id FROM Account WHERE AccountNumber IN : listAgentKeys]) {
                response.listAccountIds.add(currAccount.Id);
            }
            
            if(currComponent.Approval_Action_By__c == UserInfo.getUserId()) {
                response.doRecall = true;
            }
            system.debug('currComponent ' + currComponent);
            if(LIST_AGENT_PROFILES.contains(userProfile.strProfileName) || doSkipProfile) {
                Boolean isAgentApprovalPresent = false;
                Boolean isMatched = false;
                
                for(Approving_Agent_Criteria__c agentCriteria : [SELECT Id, Account__c, Component_Type__c, Product_Category__c, Property_Name__c, 
                                                                 Stage__c, Territory__c FROM Approving_Agent_Criteria__c 
                                                                 WHERE Account__r.AccountNumber IN : listAgentKeys AND 
                                                                 Product_Category__c =: currComponent.Product_Category__c AND 
                                                                 Component_Type__c =: currComponent.RecordType.Name]) {
                                                                    
                    if(currComponent.Submission__r.Territory__c != NULL && currComponent.Submission__r.Territory__c.contains(agentCriteria.Territory__c)) {
                        isMatched = false;
                        String strInProgressStage = currComponent.In_Progress_Stage__c;
                        
                        if(String.isNotBlank(currComponent.Addition_Stage__c) && currComponent.stage_number__c != NULL) {
                            Integer intIndex = currComponent.Component_Status__c.equalsIgnoreCase('Completed') ? Integer.valueOf(currComponent.stage_number__c) - 1 : Integer.valueOf(currComponent.stage_number__c);
                            strInProgressStage = currComponent.Addition_Stage__c.split(';').get(intIndex);
                        }
                        system.debug('Stage in agentCriteria' +agentCriteria.Stage__c);
                        system.debug('str--'+strInProgressStage );
                        system.debug('property'+agentCriteria.Property_Name__c);
                        system.debug('curr--status'+currComponent.Submission_Property__c);
                        if(currComponent.Submission_Property__c != NULL) {
                            if(String.isNotBlank(agentCriteria.Stage__c) && agentCriteria.Stage__c.contains(strInProgressStage) && currComponent.Submission_Property__c.contains(agentCriteria.Property_Name__c)) {
                                   isAgentApprovalPresent = true;
                                   isMatched = true;
                               }
                        }
                        
                        if(String.isBlank(agentCriteria.Stage__c)) {
                            isAgentApprovalPresent = true;
                            isMatched = true;
                        }
                    }
                }
                
                response.canAgentApprove = isAgentApprovalPresent;
                
                if(isAgentApprovalPresent && Approval.isLocked(strComponentId)) {
                    ProcessInstance processInstance = [SELECT Id FROM ProcessInstance WHERE TargetObjectId =: strComponentId AND Status = 'Pending'];
                    List<ProcessInstanceWorkitem> listWorkItems = [SELECT Id, ActorId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId =: processInstance.Id]; // AND ActorId =: userProfile.strUserId
                    
                    if(!listWorkItems.isEmpty()) {
                        response.isAgentApprovable = true;
                    }
                }
            }
            else {
                response.isAgentApprovable = false;
            }
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }
        System.debug('::: '+JSON.serialize(response));
        return response;
    }
    
    /**
     *  @description returns boolean value whether the Agent should be added to approval process or not
     
    public static ResponseBase doSubmitAgentApproval(String strComponentId, String strUserId, String strAgentProfile) {
        ResponseBase response = new ResponseBase();
        response.isSuccess = false;
        
        try {
            UserProfileWrap userProfile = getProfileDetails(strUserId);
            
            if(!LIST_AGENT_PROFILES.contains(userProfile.strProfileName) && LIST_AGENT_PROFILES.contains(strAgentProfile)) {
                Component__c currComponent = [SELECT Id, Name, Region__c, Addition_Stage__c, Property__c, Product_Category__c, 
                                              		 Component_Type__c, In_Progress_Stage__c 
                                              FROM Component__c 
                                              WHERE Id =: strComponentId];
                
                for(ComponentApprovingAgent__c agentSetting : [SELECT Id, Name, Stage__c 
                                                               FROM ComponentApprovingAgent__c 
                                                               WHERE Territory__c =: currComponent.Region__c 
                                                               AND PropertyName__c =: currComponent.Property__c 
                                                               AND Product_Category__c =: currComponent.Product_Category__c 
                                                               AND Component_Type__c =: currComponent.Component_Type__c]) {
					
                    if(String.isNotBlank(agentSetting.Stage__c)) {
                        if(agentSetting.Stage__c.contains(';' + currComponent.In_Progress_Stage__c + ';')) {
                            response.isSuccess = true;
                            return response;
                        }
                    }
                    else {
                        response.isSuccess = true;
                        return response;
                    }
                }
            }
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }
        
        return response;
    }
    */
    /**
     *  @description 
     */
    public static List<UserWrap> getSubmittersDetails(String strUserId) {
        List<UserWrap> response = new List<UserWrap>();
        User currUser = [SELECT Id, Name, Profile.Name, Contact.AccountId FROM User WHERE Id =: strUserId];
        
        if(LIST_AGENT_PROFILES.contains(currUser.Profile.Name)) {
            UserWrap userWrap = new UserWrap(currUser);
            userWrap.strName = 'Self';
            response.add(userWrap);
            
            for(User licenseeUser : [SELECT Id, Name FROM User WHERE ContactId IN (SELECT Id FROM Contact WHERE AccountId =: currUser.Contact.AccountId) AND Profile.Name IN : LIST_LICENSEE_PROFILES]) {
                response.add(new UserWrap(licenseeUser));
            }
        }
        
        return response;
    }
    
    public static void submitForAgentApproval(Id strComponentId, String strSubmitterUserId) {
        ComponentWrap componentObj = getComponentDetails(strComponentId, getProfileDetails(strSubmitterUserId), true);
        
        if(componentObj.isAgentApprovable == TRUE) {
            shareRecords(strComponentId, componentObj.listAccountIds);
        }
    }
    
    @future
    public static void shareRecords(Id strComponentId, List<String> listAccountIds) {
        List<Component__Share> listComponentShare = new List<Component__Share>();
        List<Submission__Share> listSubmissionShare = new List<Submission__Share>();
        Component__c currComponent = [SELECT Id, Name, Submission__c
                                      FROM Component__c 
                                      WHERE Id =: strComponentId];
        
        for(User userRec : [SELECT Id FROM User WHERE Contact.AccountId IN : listAccountIds]) {
            Component__Share componentShare1 = new Component__Share();
            componentShare1.ParentId = strComponentId;
            componentShare1.UserOrGroupId = userRec.Id;
            componentShare1.AccessLevel = 'All';
            componentShare1.RowCause = Schema.Component__Share.RowCause.Manual;
            listComponentShare.add(componentShare1);
            
            Submission__Share componentShare2 = new Submission__Share();
            componentShare2.ParentId = currComponent.Submission__c;
            componentShare2.UserOrGroupId = userRec.Id;
            componentShare2.AccessLevel = 'All';
            componentShare2.RowCause = Schema.Submission__Share.RowCause.Manual;
            listSubmissionShare.add(componentShare2);
        }
        
        if(!listComponentShare.isEmpty()) {
            Database.insert(listComponentShare, false);                
        }
        
        if(!listSubmissionShare.isEmpty()) {
            Database.insert(listSubmissionShare, false);                
        }
    }
    
   
    
    /**
     *  @description Base class
     */
    public virtual class ResponseBase {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String strMessage;
    }
    
    /**
     *  @description Base data wrapper
     */
    public class BaseDataWrap extends ResponseBase {
        @AuraEnabled public UserProfileWrap profileWrap;
        @AuraEnabled public ComponentWrap componentWrap;
        @AuraEnabled public List<UserWrap> listUsers;
        
        public BaseDataWrap() {
            this.listUsers = new List<UserWrap>();
        }
    }
    
    /**
     *  @description Profile details
     */
    public class UserProfileWrap extends ResponseBase {
        @AuraEnabled public String strUserId;
        @AuraEnabled public String strProfileId;
        @AuraEnabled public String strProfileName;
        @AuraEnabled public Boolean isAgentUser;
        @AuraEnabled public Boolean isLicenseeUser;
        @AuraEnabled public Boolean isCreativeLobUser;
        @AuraEnabled public String strUserType;
        @AuraEnabled public Boolean isInternalUser;
        
        public UserProfileWrap() {
            this.isAgentUser = false;
            this.isLicenseeUser = false;
            this.isCreativeLobUser = false;
        }
    }
    
    /**
     *  @description Component details
     */
    public class ComponentWrap extends ResponseBase {
        @AuraEnabled public Component__c currComponent;
        @AuraEnabled public String strComponentId;
        @AuraEnabled public String strRecordTypeId;
        @AuraEnabled public String strRecordTypeName;
        @AuraEnabled public Boolean isAgentApprovable;
        @AuraEnabled public UserProfileWrap currentUser;
        @AuraEnabled public String strComponentStatus;
        @AuraEnabled public List<String> listAccountIds;
        @AuraEnabled public List<StageWrap> listApprovedStages;
		@AuraEnabled public List<String> listCurrentStages;
		@AuraEnabled public List<String> listFutureStages;
        @AuraEnabled public List<String> listPreProductionValues;
        @AuraEnabled public List<String> listProductionValues;
        @AuraEnabled public List<String> listRushPriorities;
        @AuraEnabled public Integer currentStageRounds;
        @AuraEnabled public Boolean isRejected;
        @AuraEnabled public Boolean doRecall;
        @AuraEnabled public Boolean isLocked;
        @AuraEnabled public Boolean canAgentApprove;
        @AuraEnabled public Boolean imagePresent;
        @AuraEnabled public Boolean isProduction;
        @AuraEnabled public Boolean isPreProduction;
        @AuraEnabled public Boolean isCurrentUserActor;
        
        public ComponentWrap() {
            this.listAccountIds = new List<String>();
			this.listApprovedStages = new List<StageWrap>();
			this.listCurrentStages = new List<String>();
			this.listFutureStages = new List<String>();
            this.listPreProductionValues = new List<String>();
            this.listProductionValues = new List<String>();
            this.listRushPriorities = new List<String>();
            this.currentStageRounds = 0;
            this.isRejected = false;
            this.doRecall = false;
            this.isLocked = false;
            this.canAgentApprove = false;
            this.imagePresent = false;
            this.isCurrentUserActor = false;
            
            for(Schema.PicklistEntry pickListVal : Component__c.You_have_Pre_Production_samples_to_send__c.getDescribe().getPicklistValues()) {
                this.listPreProductionValues.add(pickListVal.getLabel());
            }
            
            for(Schema.PicklistEntry pickListVal : Component__c.You_have_Production_samples_to_send__c.getDescribe().getPicklistValues()) {
                this.listProductionValues.add(pickListVal.getLabel());
            }
            
            for(Schema.PicklistEntry pickListVal : Component__c.Priority__c.getDescribe().getPicklistValues()) {
                this.listRushPriorities.add(pickListVal.getLabel());
            }
        }
    }
    
    public class StageWrap {
        @AuraEnabled public String stageName;
        @AuraEnabled public Boolean IsSkipped;  
        
        public StageWrap() {
			this.stageName = '';
			this.IsSkipped = false;
        }
        
        public StageWrap(String stageName, Boolean IsSkipped) {
			this.stageName = stageName;
			this.IsSkipped = IsSkipped;
        }
    }
    
    /**
     *  @description 
     */
    public class UserWrap extends ResponseBase {
        @AuraEnabled public String strId;
        @AuraEnabled public String strName;
        
        public UserWrap(User currUser) {
            this.strId = currUser.Id;
            this.strName = currUser.Name;
        }
    }  
}