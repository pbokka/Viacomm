/**
 *   Description     :   Wrapper class for Buy Board functionality
 *                
 *   Created by      :   Subhash Garhwal 
 *
 *   Created Date    :   11/29/2018
 *
 *   Revision Log    :   V1.0 - Created
 *	
 **/
public class BuyBoard_PlanWrapper {
	
	//Define Properties
	@AuraEnabled public Plan__c buyBoardPlan{get;set;}
	@AuraEnabled public Boolean hasProducts {get;set;}
	@AuraEnabled public List<BBProductDataWrapper> BBProductData{get;set;}
	@AuraEnabled public Id currentUser {get;set;}
	@AuraEnabled public Boolean displaySentMSG {get;set;}
	@AuraEnabled public Boolean displayDecisionMSG {get;set;}
	@AuraEnabled public String headerMSG {get;set;}
	@AuraEnabled public Boolean displayRecallButton {get;set;}
	@AuraEnabled public Boolean createProductButtonEditable {get;set;}
	@AuraEnabled public Boolean isSuccess {get;set;}
    @AuraEnabled public String strMessage {get;set;}
    @AuraEnabled public Boolean displayFooterSection {get;set;}
    @AuraEnabled public Boolean disableRecall {get;set;}
    @AuraEnabled public String userType {get;set;}
	
	
	//Constructor
	public BuyBoard_PlanWrapper() {
		BBProductData = new List<BBProductDataWrapper>();
		currentUser = UserInfo.getUserId();
		displaySentMSG = false;
		displayDecisionMSG = false;
		displayRecallButton = false;
		hasProducts = false;
		createProductButtonEditable = true;
		isSuccess = false;
		displayFooterSection = false;
		disableRecall = false;
		userType = UserInfo.getUserType();
	} 
	
	//Wrapper class to hold the Product data
	public class BBProductDataWrapper {
		
		//Define Properties
	 	@AuraEnabled public Plan__c bBProduct {get;set;}
	 	@AuraEnabled public List<BuyboardProductPropertyData> properties {get;set;}
	 	@AuraEnabled public List<ProductDataWrapper> products {get;set;}
	 	@AuraEnabled public sharinpix__SharinPixImage__c sharinpixImage {get;set;}
	 	@AuraEnabled public Boolean isPropertiesReadOnly {get;set;}
	 	@AuraEnabled public Comment__c creatorNotes {get;set;}
	 	@AuraEnabled public Comment__c reviewerNotes {get;set;}
	 	@AuraEnabled public Id currentUser{get;set;}
		@AuraEnabled public String currentUserName {get;set;}
		@AuraEnabled public Boolean editButtonEditable {get;set;}
		@AuraEnabled public Boolean createSubmissionButtonEditable {get;set;}
		@AuraEnabled public String status {get;set;}
		@AuraEnabled public String strMessage {get;set;}
	 	
	 	//Constructor
	 	public BBProductDataWrapper() {
	 		
	 		//Set Default Perperties
	 		bBProduct = new Plan__c();
	 		properties = new List<BuyboardProductPropertyData>();
	 		creatorNotes = new Comment__c(Name = BuyBoard_Constants.PLAN_CREATOR_NOTES_NAME);
	 		reviewerNotes = new Comment__c(Name = BuyBoard_Constants.PLAN_REVIEWER_NOTES_NAME);
	 		sharinpixImage = new sharinpix__SharinPixImage__c();
	 		isPropertiesReadOnly = true;
	 		currentUser = UserInfo.getUserId();
	 		editButtonEditable = false;
	 		createSubmissionButtonEditable = false;
	 	}
	}

	//Wrapper class to hold the Properties for Product
	public class BuyboardProductPropertyData implements Comparable {
     	
    	//Define Properties
     	@AuraEnabled public String properties;
     	@AuraEnabled public Boolean isSelected;
     	
		//Constuctor
     	public BuyboardProductPropertyData(String properties, Boolean isSelected) {
     		
     		//Set Properties
     		this.properties = properties;
     		this.isSelected = isSelected;    		
		}
        public Integer compareTo(Object objToCompare) {
            return properties.compareTo(((BuyboardProductPropertyData)objToCompare).properties);
    	}

	}
	
	//Wrapper class to hold the Products
	public class ProductDataWrapper {
 	
	 	//Define Properties
	 	@AuraEnabled public String productName;
	 	
	 	//Constuctor
	 	public ProductDataWrapper() {}
 	}
 	//Naman Jain Code optimization 14/03/19 Start
 	public class ResponseBaseWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String strMessage;
    }
 	//Naman Jain Code optimization 14/03/19 Start

}