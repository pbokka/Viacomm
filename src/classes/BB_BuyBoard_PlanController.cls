/**
 *   Description     :   Controller class Used to display BuyBoardPlan Details
 *                
 *   Created by      :   Subhash Garhwal 
 *
 *   Created Date    :   11/29/2018
 *
 *   Revision Log    :   V1.0 - Created
 *	
 **/
/*
	@Naman Code Optimization 14/03/19 
*/
public without sharing class BB_BuyBoard_PlanController {
	
	
	/**
     *	@description	: 	This method is used to get base details for Buyboard Plan
     *
     *	@args           :   String
     *
     *	@return         :   BuyBoard_PlanWrapper
     *
     *	@revision Log   :   V1.0 - Created - 11/29/2018 - Subhash Garwal 
     *	
     **/
     
     @AuraEnabled
     public static BuyBoard_PlanWrapper getBuyBoardDetails(String buyBoardPlanId){
     	
     	//Instance of BuyBoard_PlanWrapper
     	//Testing Apex Class CHange in Buy Board Class
		BuyBoard_PlanWrapper buyBoardPlanData = new BuyBoard_PlanWrapper();
		buyBoardPlanData.isSuccess = true;
		
		try {

			//Check for Buy Board Plan Id
	     	if(String.isNotBlank(buyBoardPlanId) && buyBoardPlanId instanceof Id)  {
	     		
	     		//SOQL on BuyBoard Plan
			    Plan__c bBPlan = [Select Id, Name, Account__r.Name, Reviewer__c, Reviewer__r.Name, Properties__c, CreatedBy.Name, 
			    						Description__c, Main_File_URL__c,SharinPix_Image__c, Main_File_Format__c,LastModifiedById,
			    						 SharinPix_Image_Id__c, Status__c, OwnerId, Recall__c, Sent_Date__c, Sent_By__c, Sent_To__c, Sent_By__r.Name, Sent_To__r.Name,
			    						 (Select Id,Status__c,LastModifiedById,Submission__c From Plans__r ORDER BY LastModifiedDate DESC) 
			    						 From Plan__c
			    						 Where Id =: buyBoardPlanId LIMIT 1];
				
				//Set Plan in wrapper
				buyBoardPlanData.buyBoardPlan = bBPlan;
				if(bBPlan.Plans__r != null && bBPlan.Plans__r.size() > 0)
					buyBoardPlanData.hasProducts = true;	
				
				//Code to control the MSG visiability on the Buy Board Plan header
				/********************      Start      ****************/
				if(bBPlan.Sent_By__c != null && bBPlan.Sent_To__c != null && bBPlan.Sent_Date__c != null) {
					String region = '';
					Datetime dt = datetime.newInstance(bBPlan.Sent_Date__c.year(),bBPlan.Sent_Date__c.month(),bBPlan.Sent_Date__c.day());
					String sentDate = dt.format('dd-MM-yy');
					if([Select TimeZoneSidKey from User where id =: USerInfo.getUserId()].TimeZoneSidKey.containsIgnoreCase(System.Label.PD_America)) {
						region = System.Label.PD_USA;
						sentDate = dt.format('MM-dd-yy');
					}
					//Sent By 
					if(bBPlan.Sent_By__c == UserInfo.getUserId() && bBPlan.Status__c == BuyBoard_Constants.PLAN_STATUS_SUBMITTED_FOR_REVIEW) {
						
						//Set Header flag and message
						buyBoardPlanData.displaySentMSG = true;
						String sentToMessage = System.Label.PD_BB_Sent_To_Message;
						buyBoardPlanData.headerMSG = sentToMessage.replace('[Name]', bBPlan.Sent_To__r.Name)
															.replace('[Date]',sentDate);
						buyBoardPlanData.displayRecallButton = true;
					
					} else if(bBPlan.Sent_To__c == UserInfo.getUserId() && bBPlan.Status__c == BuyBoard_Constants.PLAN_STATUS_SUBMITTED_FOR_REVIEW) {
						
						//Set Header flag and message
						buyBoardPlanData.displaySentMSG = true;
						String sentToMessage = System.Label.PD_BB_Sent_For_Review_Message;
						buyBoardPlanData.headerMSG = sentToMessage.replace('[Name]', bBPlan.Sent_By__r.Name)
															.replace('[Date]',sentDate);
						
					} else if(bBPlan.Sent_To__c == UserInfo.getUserId() && bBPlan.Status__c == BuyBoard_Constants.PLAN_STATUS_Reviewed) {
						
						//Set Header flag and message
						buyBoardPlanData.displayDecisionMSG = true;
						String sentToMessage = System.Label.PD_BB_Decision_Receive_Message;
						buyBoardPlanData.headerMSG = sentToMessage.replace('[Name]', bBPlan.Sent_By__r.Name)
															.replace('[Date]',sentDate);
						
					} else if(bBPlan.Sent_By__c == UserInfo.getUserId() && bBPlan.Status__c == BuyBoard_Constants.PLAN_STATUS_Reviewed) {
						
						//Set Header flag and message
						buyBoardPlanData.displayDecisionMSG = true;
						//@Naman 27/02/19 Add Labels Start
						String sentToMessage = System.Label.PD_BB_Decision_Sent_Message;
						buyBoardPlanData.headerMSG = sentToMessage.replace('[Name]', bBPlan.Sent_To__r.Name)
															.replace('[Date]',sentDate);

						buyBoardPlanData.displayRecallButton = true;
					}
				}
				/********************      END      ****************/
				if(bBPlan.LastModifiedById != UserInfo.getUserId()) {
					buyBoardPlanData.disableRecall = true;
				}
				//Code to control the visiblity of footer
				buyBoardPlanData.displayFooterSection = false;
				for(Plan__c p : bBPlan.Plans__r) {
					if(p.Status__c != System.Label.PD_Accepted && p.Status__c != System.Label.PD_Denied) {
						buyBoardPlanData.displayFooterSection = true;
					}
				}
				if(bBPlan.Plans__r.size() > 0 && bBPlan.Plans__r[0].LastModifiedById != UserInfo.getUserId()) {
					buyBoardPlanData.disableRecall = true;
				}
			}
		}
		catch(Exception ex) {
            buyBoardPlanData.isSuccess = false;
            buyBoardPlanData.strMessage = ex.getMessage();
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_BuyBoard_PlanController,Method - getBuyBoardDetails', ex.getLineNumber() + ' - ' + ex.getMessage()); 
        }	
		
		//Return
		return buyBoardPlanData;
     }
     	
     
	/**
     *	@description	: 	This method is used to get details of all the Child Buy board Products
     *
     *	@args           :   String, String, String
     *
     *	@return         :   List<BuyBoard_PlanWrapper.BBProductDataWrapper>
     *
     *	@revision Log   :   V1.0 - Created - 11/29/2018 - Subhash Garwal 
     *	
     **/
     
     @AuraEnabled
     public static BuyBoard_PlanWrapper getBuyBoardProductDetails(String buyBoardPlanId,String sorted,String status){
     	
     	//Instance of BuyBoard_PlanWrapper
		BuyBoard_PlanWrapper buyBoardPlanData = new BuyBoard_PlanWrapper();
		buyBoardPlanData.isSuccess = true;
     	
     	try {
	     	//List of BB Product Wrapper
			List<BuyBoard_PlanWrapper.BBProductDataWrapper> bBProductWrapper = new List<BuyBoard_PlanWrapper.BBProductDataWrapper>();
	     	
	         //List of BBProduct Plan
	         List<Plan__c> planList = new List<Plan__c>();
	          		
	     	//Check for Buy Board Plan 
	     	if(String.isNotBlank(buyBoardPlanId) && buyBoardPlanId instanceof Id){
	     		
	     		//check for sorting direction
	     		if(String.isBlank(sorted))
					sorted = System.Label.PD_Desc;
	     		Set<String> setCommentNames = new Set<String>{BuyBoard_Constants.PLAN_CREATOR_NOTES_NAME, BuyBoard_Constants.PLAN_REVIEWER_NOTES_NAME};
	     		
	     		//SOQL query variable
	     		String sOQLQuery = 'Select Id, Name, Properties__c, BBProduct__c, Parent__c, Sent_By__c, Sent_To__c,Status__c, Temp_Status__c, Parent__r.OwnerId, Parent__r.Recall__c,'
	     							+ 'Parent__r.Sent_By__c, Parent__r.Sent_To__c, Parent__r.Status__c,SharinPix_Image__c, Main_File_URL__c, Main_File_Format__c, SharinPix_Image_Id__c, Submission__c, Submission__r.Name,'
	     							+ '(Select Id, Name, Comment__c From Comment__r Where Name IN : setCommentNames ORDER BY Name ASC LIMIT 2)' 
	     							+ ' From Plan__c Where Parent__c =\'' + buyBoardPlanId + '\'';   		
	     		
	     		//Add Status and sorting check
				if(String.isBlank(status))
					status = System.Label.PD_All;
				else if(status == System.Label.PD_All)
					sOQLQuery += ' Order By LastModifiedDate ' + sorted;
				else
	     		 	sOQLQuery += ' AND Status__c= \'' + status + '\' Order By LastModifiedDate ' + sorted + ', Name ' + sorted;
				
	    		//SOQL over the BB Products
	    		List<Plan__c> bBProducts = database.query(sOQLQuery);
	    		
				//Loop over the Products
	     		for(Plan__c bBProduct : bBProducts) {
	     			
					//Instance of BBProductDataWrapper
	     			BuyBoard_PlanWrapper.BBProductDataWrapper bBProductWrap = new BuyBoard_PlanWrapper.BBProductDataWrapper();
	     			
	     			//Add Details
	     			bBProductWrap.bBProduct = bBProduct;
	     			
	     			//This code to control the edit button's visiability
	     			if((bBProduct.Status__c == BuyBoard_Constants.PLAN_STATUS_NEW /*&& bBProduct.Parent__r.OwnerId == UserInfo.getUserId() By Naman NPI-4112*/)
	     				|| (bBProduct.Status__c == BuyBoard_Constants.PLAN_STATUS_DECISION_PENDING && ((bBProduct.Parent__r.OwnerId == UserInfo.getUserId() && (bBProduct.Parent__r.Sent_To__c == UserInfo.getUserId() || bBProduct.Parent__r.Sent_To__c == null))
	     					|| bBProduct.Parent__r.Sent_To__c == UserInfo.getUserId())))
	     				bBProductWrap.editButtonEditable = true;
					
					//This code to control the edit button's visiability
					if(bBProduct.Status__c == BuyBoard_Constants.PLAN_STATUS_ACCEPTED && bBProduct.Parent__r.Status__c == BuyBoard_Constants.PLAN_STATUS_Reviewed
						&& bBProduct.Parent__r.OwnerId == UserInfo.getUserId() && bBProduct.Submission__c == null)
						bBProductWrap.createSubmissionButtonEditable = true;
	     			
	     			//Check for Comment
	     			if(bBProduct.Comment__r != null && bBProduct.Comment__r.size() > 0) {
	     				if( bBProduct.Comment__r[0].Name == BuyBoard_Constants.PLAN_CREATOR_NOTES_NAME) {
	     					bBProductWrap.creatorNotes = bBProduct.Comment__r[0];
	     				}
	     				else {
	     					bBProductWrap.reviewerNotes = bBProduct.Comment__r[0];	
	     				}
						//Add Comment Details
						
	     				//Check for reviewr notes
	     				if(bBProduct.Comment__r.size() > 1)
	     					bBProductWrap.reviewerNotes = bBProduct.Comment__r[1];		
	     			}
	     			
	     			//Add wrapper details in list
	     			bBProductWrapper.add(bBProductWrap);
	     		}
			}
			List<Plan__c> pp = [SELECT Id,Sent_By__c,OwnerId,Reviewer__c,Sent_To__c FROM Plan__c WHERE id = :buyBoardPlanId];
			
			buyBoardPlanData.displayFooterSection = false; 
			if((pp[0].OwnerId == UserInfo.getUserId() && pp[0].Sent_By__c != UserInfo.getUserId()) ||
				pp[0].Sent_To__c == UserInfo.getUserId()) {
				buyBoardPlanData.displayFooterSection = true;
			}
			//Return 
			buyBoardPlanData.BBProductData = bBProductWrapper;
     	
     	} catch(Exception ex) {
            buyBoardPlanData.isSuccess = false;
            buyBoardPlanData.strMessage = ex.getMessage();
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_BuyBoard_PlanController,Method - getBuyBoardProductDetails', ex.getLineNumber() + ' - ' + ex.getMessage()); 
        }
        
        //Return 
        return buyBoardPlanData;
	}
     
	/**
     *	@description	: 	This method is used update creator Notes under BBProduct Plan
     *
     *	@args           :   String, String
     *
     *	@return         :   Comment__c
     *
     *	@revision Log   :   V1.0 - Created - 11/29/2018 - Subhash Garwal 
     *	
     **/
     
     @AuraEnabled
     public static Comment__c editCreatorNotes(String creatorNotes, String productRecordId ){
     	//Added by Naman 26 Feb 2019 NPI-558 Start
     	Comment__c notes = (Comment__c)JSON.deserialize(creatorNotes,Comment__c.class );
     	try{
	     	//Get Comment
	     	
	     	//Update Plan
	     	notes.Plan__c = productRecordId;
	     	
	     	//Update Notes
	     	upsert notes;
	     	//@Naman NPI-3674 26/02/19 Start
	     	Plan__c plan = new Plan__c(Id = productRecordId);
	     	update plan;
	     	//@Naman NPI-3674 26/02/19 End
     	}
     	catch(Exception ex) {
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_BuyBoard_PlanController,Method - editCreatorNotes', ex.getLineNumber() + ' - ' + ex.getMessage()); 
     	}
     	//Return
     	return notes;
     	//Added by Naman 26 Feb 2019 NPI-558 End
     }
    
	/**
     *	@description	: 	This method is used to update Plan Details
     *
     *	@args           :   String, String
     *
     *	@return         :   BuyBoard_PlanWrapper
     *
     *	@revision Log   :   V1.0 - Created - 12/05/2018 - Subhash Garwal 
     *	
     **/
     @AuraEnabled
	public static BuyBoard_PlanWrapper submitBuyBoardPlan(String buyBoardPlanId,  String sentToId){
		
		//Instance of BuyBoard_PlanWrapper
		BuyBoard_PlanWrapper buyBoardPlanData = new BuyBoard_PlanWrapper();
		buyBoardPlanData.isSuccess = true;
		buyBoardPlanData.strMessage = System.Label.PD_BB_Submit_Success;
		try {
			//Check for BBPlans
	     	if(String.isNotBlank(buyBoardPlanId) && buyBoardPlanId instanceof Id) {
	     		
	     		//Get Buy Board Plan
	     		List<Plan__c> buyBoardPlanDetails = [Select Id, Name, Status__c, Sent_By__c, Sent_To__c, Temp_Status__c, Previous_Status__c From Plan__c Where
					     										(Id =: buyBoardPlanId AND RecordTypeId =: BuyBoard_Constants.PLAN_BUY_BOARD_RECORD_TYPE_ID)
					     										OR (Parent__c =: buyBoardPlanId AND RecordTypeId =: BuyBoard_Constants.PLAN_BUY_BOARD_PRODUCT_TYPE_ID)
					     										ORDER BY CreatedDate ASC];
	     		
	     		//Check for size
	     		if(buyBoardPlanDetails.size() > 0) {
	     			
	     			//Get Main Buy Board Plan
	     			Plan__c buyBoardPlan = buyBoardPlanDetails[0];
	     			
	     			//Remove First element from list
	     			buyBoardPlanDetails.remove(0);
	     			
	     			//List of Buy Board Products
	     			List<Plan__c> buyBoardProducts = buyBoardPlanDetails;
	     			System.debug(buyBoardPlan.Id);
	     			//List of Plans to update
     				List<Plan__c> plans = new List<Plan__c>();
     				
     				//Check for Products
	     			if(buyBoardProducts != null && buyBoardProducts.size() > 0) {
	     				
	     				//Loop over the Products
	     				for(Plan__c bBProduct : buyBoardProducts) {
	     					
	     					//Check for Status
	     					if(bBProduct.Status__c != System.Label.PD_Accepted && bBProduct.Status__c != System.Label.PD_Denied) {
	     						
	     						//Check for main Buy Board Plan
	     						if((buyBoardPlan.Sent_By__c == null && buyBoardPlan.Sent_To__c == null) || bBProduct.Status__c == System.Label.PD_New) {
	     							System.debug(buyBoardPlan.Sent_By__c +'' + buyBoardPlan.Sent_To__c);
	     							//Update Status of the BB Products
	     							bBProduct.Previous_Status__c = bBProduct.Status__c;
		     						bBProduct.Status__c = System.Label.PD_Decision_Pending;
		     						bBProduct.Temp_Status__c = System.Label.PD_Decision_Pending;	
	     						
	     						} else if(buyBoardPlan.Sent_To__c != null && buyBoardPlan.Sent_To__c == UserInfo.getUserId()){
	     								System.debug(buyBoardPlan.Sent_By__c +'' + buyBoardPlan.Sent_To__c);
									//Update Status of the BB Products
									bBProduct.Previous_Status__c = bBProduct.Status__c;
									if(bBProduct.Temp_Status__c != null)
		     							bBProduct.Status__c = bBProduct.Temp_Status__c;
	     						}
	     						//Add record in list
	     						plans.add(bBProduct);
	     					}
	     				}
	     			}
     				
     				//Check for Buy Board Plan
     				if((buyBoardPlan.Sent_By__c == null && buyBoardPlan.Sent_To__c == null && buyBoardPlan.Status__c == BuyBoard_Constants.PLAN_STATUS_NEW)
     					|| (buyBoardPlan.Status__c == BuyBoard_Constants.PLAN_STATUS_Reviewed && buyBoardPlan.Sent_To__c == UserInfo.getUserId())) {
     					
     					//Update Buy Board Plan
     					buyBoardPlan.Previous_Status__c = buyBoardPlan.Status__c; 
     					buyBoardPlan.Status__c = System.Label.PD_Submitted_for_Review;
     					buyBoardPlan.Reviewer__c = sentToId;
     					buyBoardPlan.Sent_Date__c = System.today();
     					buyBoardPlan.Recall__c = true;
     					
     				} else if(buyBoardPlan.Status__c == BuyBoard_Constants.PLAN_STATUS_SUBMITTED_FOR_REVIEW && buyBoardPlan.Sent_To__c == UserInfo.getUserId()){
     					
     					//Update Buy Board Plan
     					buyBoardPlan.Previous_Status__c = buyBoardPlan.Status__c;
     					buyBoardPlan.Status__c = System.Label.PD_Reviewed;
     					buyBoardPlan.Sent_Date__c = System.today();
     					buyBoardPlan.Recall__c = true;
     				}
	     				
					//Update sent to and sent by details
	     			buyBoardPlan.Sent_By__c = UserInfo.getUserId();
	     			buyBoardPlan.Sent_To__c = sentToId;
	     			
	     			//Add record in list to update
	     			plans.add(buyBoardPlan);
	     			
	     			//Check for list size
     				if(plans.size() > 0)
     					update plans;
	     		}
	     	}
		} catch (Exception ex) {
			
			buyBoardPlanData.isSuccess = false;
			buyBoardPlanData.strMessage = ex.getMessage();
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_BuyBoard_PlanController,Method - submitBuyBoardPlan', ex.getLineNumber() + ' - ' + ex.getMessage()); 

		}
		//Return response
		return buyBoardPlanData;

     }
     
    /**
     *	@description	: 	This method is used to update Plan Details
     *
     *	@args           :   String,String
     *
     *	@return         :   void
     *
     *	@revision Log   :   V1.0 - Created - 12/05/2018 - Subhash Garwal 
     *	
     **/
     @AuraEnabled
     public static BuyBoard_PlanWrapper updateTempStatus(String bBProductId ,String tempStatus){
     	
     	//Instance of BuyBoard_PlanWrapper
		BuyBoard_PlanWrapper buyBoardPlanData = new BuyBoard_PlanWrapper();
		buyBoardPlanData.isSuccess = true;
		
		try {
			//check for BuyBoardProduct Id
	     	if(String.isNotBlank(bBProductId) && bBProductId instanceof Id && String.isNotBlank(tempStatus)) {
	     		String parentId = [SELECT Id,Parent__c FROM Plan__c WHERE id = :bBProductId LIMIT 1].Parent__c;
	     		//Check for
	     		Plan__c p1 = new Plan__c(Id = bBProductId, Temp_Status__c = tempStatus);
	     		Plan__c p2 = new Plan__c(Id = parentId);
	     		update new List<Plan__c>{p1,p2};
	        }	
		} catch (Exception ex) {
			
			buyBoardPlanData.isSuccess = false;
			buyBoardPlanData.strMessage = ex.getMessage();
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_BuyBoard_PlanController,Method - updateTempStatus', ex.getLineNumber() + ' - ' + ex.getMessage()); 
		}
		//Return response
		return buyBoardPlanData;
		
     }
     
	/**
     *	@description	: 	This method is for Recall button.
     *
     *	@args           :   String
     *
     *	@return         :   void
     *
     *	@revision Log   :   V1.0 - Created - 12/12/2018 - Subhash Garwal 
     *	
     **/
	@AuraEnabled
	public static BuyBoard_PlanWrapper recallBuyBoardPlan(String buyBoardPlanId) {
		
		//Instance of BuyBoard_PlanWrapper
		BuyBoard_PlanWrapper buyBoardPlanData = new BuyBoard_PlanWrapper();
		buyBoardPlanData.isSuccess = true;

		buyBoardPlanData.strMessage = System.Label.PD_BB_Recall_Success;
		
		try {
		
			//Check for Buy Board Id
			if(String.isNotBlank(buyBoardPlanId) && buyBoardPlanId instanceof Id) {
				
				//Get Buy Board Plan
	     		List<Plan__c> buyBoardPlanDetails = [Select Id, Name,OwnerId, Status__c, Sent_By__c, Sent_To__c, Temp_Status__c, Previous_Status__c,Submission__c,LastModifiedById,Reviewer__c 
	     											From Plan__c 
	     											Where (Id =: buyBoardPlanId AND RecordTypeId =: BuyBoard_Constants.PLAN_BUY_BOARD_RECORD_TYPE_ID)
			     										OR (Parent__c =: buyBoardPlanId AND RecordTypeId =: BuyBoard_Constants.PLAN_BUY_BOARD_PRODUCT_TYPE_ID)
			     										ORDER BY CreatedDate ASC];
				
				//Check for plans
				if(buyBoardPlanDetails.size() > 0) {
					
					//Get Main Buy Board Plan
					Plan__c buyBoardPlan = buyBoardPlanDetails[0];
	     			
	     			//Remove First element from list
	     			buyBoardPlanDetails.remove(0);
	     			
	     			//List of Buy Board Products
	     			List<Plan__c> buyBoardProducts = buyBoardPlanDetails;
	     			
	     			//List of Plans to update
	 				List<Plan__c> plans = new List<Plan__c>();
	 				Boolean callByOwner = true;
	 				if(buyBoardPlan.Sent_To__c == buyBoardPlan.OwnerId) {
	 					callByOwner = false; 
	 				}
 					if(buyBoardPlan.LastModifiedById != UserInfo.getUserId()) {
 						buyBoardPlanData.isSuccess = false;
 						buyBoardPlanData.strMessage = System.Label.PD_Recall_Error;
 						return buyBoardPlanData;
 					}
	 				//Check Buy Board Plan Previous Status
	 				if((buyBoardPlan.Previous_Status__c == BuyBoard_Constants.PLAN_STATUS_NEW || buyBoardPlan.Previous_Status__c == BuyBoard_Constants.PLAN_STATUS_Reviewed
	 					|| buyBoardPlan.Previous_Status__c == BuyBoard_Constants.PLAN_STATUS_SUBMITTED_FOR_REVIEW) && buyBoardPlan.Sent_By__c == UserInfo.getUserId()) {
						
						//Update Buy Board Plan Details
						buyBoardPlan.Status__c = buyBoardPlan.Previous_Status__c;
						buyBoardPlan.Recall__c = false;
						
						//Check if Plan is initially submitted
						if(buyBoardPlan.Previous_Status__c == BuyBoard_Constants.PLAN_STATUS_NEW) {
							
							//Update the reviewer details
							buyBoardPlan.Sent_By__c = null;
							buyBoardPlan.Sent_To__c = null;	
						
						} else {
							
							//Variable to hold the Sent By and Sent To details
							Id sentById = buyBoardPlan.Sent_By__c;
							Id sentToId = buyBoardPlan.Sent_To__c;
							
							//Update details
							buyBoardPlan.Sent_By__c = sentToId;
							buyBoardPlan.Sent_To__c = sentById;
						}
						
						//Add Record in list
						plans.add(buyBoardPlan);
						String lastModifiedId = [SELECT LastModifiedById FROM Plan__c 
												WHERE Parent__c =: buyBoardPlanId 
												ORDER BY LastModifiedDate DESC LIMIT 1].LastModifiedById;
						if(lastModifiedId != UserInfo.getUserId()) {
							buyBoardPlanData.isSuccess = false;
							buyBoardPlanData.strMessage = System.Label.PD_Recall_Error;
							return buyBoardPlanData;
						}
						//Loop over the Buy Board Product
						for(Plan__c bBProduct : buyBoardProducts) {
							if(callByOwner) {
								if(bBProduct.Status__c ==System.Label.PD_Decision_Pending)
									bBProduct.Status__c = bBProduct.Previous_Status__c;

									
							}
							else{
								if(bBProduct.Submission__c == null){
									bBProduct.Status__c = bBProduct.Previous_Status__c;
								}
							} 
							
							//Add Record in list
							plans.add(bBProduct);
						}
						
						//Update records
						if(plans.size() > 0)
							update plans;
	 				} 
				}
			}
		} catch (Exception ex) {
			
			buyBoardPlanData.isSuccess = false;
			buyBoardPlanData.strMessage = ex.getMessage();
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_BuyBoard_PlanController,Method - recallBuyBoardPlan', ex.getLineNumber() + ' - ' + ex.getMessage()); 
		}
		//Return response
		return buyBoardPlanData;
	}
     
	/**
     *	@description	: 	This method is used to create Submission and Component for Buy Board Product
     *
     *	@args           :   String
     *
     *	@return         :   void
     *
     *	@revision Log   :   V1.0 - Created - 12/11/2018 - Subhash Garwal 
     *	
     **/
     @AuraEnabled
     public static String createSubmission(String bbProductRecordId){
     	String message='';
     	try {
	     	//check for BuyBoardProduct Id
	     	if(String.isNotBlank(bbProductRecordId)) {
	     		//@Naman NPI-3676 26/02/19 Start
	     		Plan__c plan = [SELECT Id, Name, Account__c ,Parent__c, BBProduct__c, Parent__r.Account__c, Properties__c,Plan_Category__c FROM Plan__c WHERE Id =: bbProductRecordId];
	     		//@Naman NPI-3676 26/02/19 End
	     		//Check for Product
	     		if(plan != null) {
	     			//Query on ContractsPd
	                //@Naman NPI-3676 26/02/19 Start
	                Contractspd__c contract;
	                List<String> planProperties = plan.Properties__c.split(';');
	                //Naman code optimization 14/03/19 Start
	                List<Contractspd__c> contractList = BB_PlanHelperController.getContarct( plan.Parent__r.Account__c);
	                //Naman code optimization 14/03/19 End
	                List<Contractspd__c> finalContracts = new List<Contractspd__c>();
	                finalContracts.addAll(contractList);
	                for(Contractspd__c con : contractList) {
	                	//Naman Jain NPI-3892 06/03/19 Start
	                  	if(!String.isEmpty(con.Product_lt__c) && !String.isEmpty(con.Product_Hierarchy__c) && !String.isEmpty(con.Properties_lt__c) && con.Product_lt__c.containsIgnoreCase(plan.BBProduct__c)) {
                		//Naman Jain NPI-3892 06/03/19 End
	                  		Set<String> conProperties = new Set<String>(con.Properties_lt__c.split(';'));
	                  		conProperties.retainAll(planProperties);
	                  		if(conProperties.size() == planProperties.size()) {
	                  			contract = con;
	                  			break;
	                  		}
	                  	}
	                }
	     			//@Naman NPI-3676 26/02/19 End
	                if(contract != null){  
	                    //Get the Sharinpix Images from Plan
		     			List<sharinpix__SharinPixImage__c> images = [Select Id, Name, SharinPix_Album__c, Component__c, Plan__c From sharinpix__SharinPixImage__c
		     																Where Plan__c =: plan.Id ORDER BY CreatedDate DESC LIMIT 1];
		     			sharinpix__SharinPixImage__c imgRecId;
		     			if(!images.isEmpty())	
		     				imgRecId  = images[0]; 																                     
		     			//Instance of the Submission
		     			Submission__c submission = new Submission__c();
		     			
		     			//Update Submission field values
						//Naman NPI-558 08/03/19 Start
		     			submission.RecordTypeId = BuyBoard_Constants.SUBMISSION_PRODUCT_RECORD_TYPE_ID;
						//Naman NPI-558 08/03/19 End
		     			submission.Name = plan.Name;
		     			if(plan.Account__c != null) {
		     				submission.Account__c = plan.Account__c;
		     			}
		     			if(plan.Properties__c != null) {
		     				submission.Properties__c = plan.Properties__c;
		     			}
		     			//Naman 27/02/19 Add Label Start 
		     			submission.Item_for_Sale__c = System.Label.PD_Product_Retail_Sale;
		     			//Naman 27/02/19 Add Label End 
		     			//submission.Year_On_shelf_1__c = String.valueof(System.today().year());commented by Naman Jain 13/03/19
		     			submission.Year_on_Shelf__c = String.valueof(System.today().year());
		     			if(contract.Location_t__c != null) {
		     				submission.Location__c = contract.Location_t__c;
		     			}
		     			if(contract.Region_t__c != null) {
		     				submission.Region__c = contract.Region_t__c;
		     			}
		     			//@Naman NPI-3676 28/02/19 Start
		     			//submission.ProductCategory__c = plan.Plan_Category__c;
		     			if(contract.Product_Hierarchy__c != null && plan.BBProduct__c != null) {
		     				submission.ProductCategory__c = BB_PlanHelperController.getCategory(contract.Product_Hierarchy__c,plan.BBProduct__c);
		     			}
		     			//@Naman NPI-3676 28/02/19 End
		     			if(plan.BBProduct__c != null) {
		     				submission.Product__c = plan.BBProduct__c;
		     			}
		     			//@Naman NPI-3676 06/03/19 Start
		     			if(contract.Brands_lt__c != null && !contract.Brands_lt__c.containsIgnoreCase(';')){
		     				submission.Brands__c = contract.Brands_lt__c;
		     			}
		     			//@Naman NPI-3676 06/03/19 End
	                    //submission.Agent__c = contract.Agent__r.Name; commented by Naman Jain 13/03/19
	                    if(contract.Agent__c != null) {
	                   		submission.Agent_Account__c = contract.Agent__c;
	                   	}
		     			submission.CreatedFromPlan__c = true;
		     			if(plan.Id != null) {
		     				submission.Plan__c = plan.Id;
		     			}
		     			if(contract.Contract_Id_t__c != null) {
		     				submission.Contractnumber__c  = contract.Contract_Id_t__c;
		     			}
		     			if(imgRecId != null) {
		     				submission.SharinPix_Main_File__c = imgRecId.Id;
		     			}
		     			//Insert Submission
		     			submission = BB_PlanHelperController.insertSub(submission);
		     			//insert submission;
		     			if(submission.Id != null) {
		     				plan.submission__c  = submission.Id;
		     			}
		     			update plan;
		     			//Instance of the Component
		     			Component__c component = new Component__c();
		     			//Populate field values
		     			component.Name = plan.Name;
		     			component.Name__c = plan.Name;
		     			component.Submission__c = submission.Id;
		     			if(imgRecId != null)
		     				component.SharinPix_Main_File__c = imgRecId.Id;
		     			//Insert Component
		     			insert component;
		     			//Instance of the Album
		     			sharinpix__SharinPixAlbum__c album = new sharinpix__SharinPixAlbum__c();
		     			//Update album details
		     			album.Component__c = component.Id;
		     			//Insert album
		     			insert album;
		     			//Update Details on the Image
		     			for(sharinpix__SharinPixImage__c imgRec : images) {
		     				//Update Album
		     				imgRec.SharinPix_Album__c = album.Id;
		     				imgRec.Component__c = component.Id;
		     			}
		     			//Check for Images
		     			if(images.size() > 0)
							BB_PlanHelperController.updateImages(images); 
		     				message=System.Label.PD_Submission_Success;
	            	} else{
	                  	message= System.Label.PD_BB_No_Contract;
	                }
	     		}
	     	}
     		return message;
     	}
     	catch (Exception ex) {
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_BuyBoard_PlanController,Method - createSubmission', ex.getLineNumber() + ' - ' + ex.getMessage()); 
			return message = ex.getMessage();
		}
     }

    /**
     *  @description This method provides the list of fields available in config for Submission
     */
    // Submission Required Fields
    public static Boolean listAllSelFields(String subRecordId) {
        List<String> listFields = new List<String>();
        string currentUserType = ListViewHelper.getUserType(UserInfo.getUserId());

        try {
            DatatableObjectConfigurations__c qyertMDT = [SELECT Sobject_Name__c,AgentUserFieldAPINames__c, LicenseeUserFieldAPINames__c, InternalUserFieldAPINames__c
                                                         FROM DatatableObjectConfigurations__c
                                                         WHERE Sobject_Name__c = :System.Label.PD_Submission_cRequired
                                                         AND Name = :System.Label.PD_Submission_Required_Fields
                                                         LIMIT 1];
            if( String.isNotBlank(currentUserType) ) {
                if(currentUserType.equalsIgnoreCase(Constants.AGENT)) {
                    listFields.addAll((list<String>) JSON.deserialize(qyertMDT.AgentUserFieldAPINames__c, list<String>.class));
                }else if(currentUserType.equalsIgnoreCase(Constants.LICENSEE)) {
                    listFields.addAll((list<String>) JSON.deserialize(qyertMDT.LicenseeUserFieldAPINames__c, list<String>.class));
                }else {
                    listFields.addAll((list<String>) JSON.deserialize(qyertMDT.InternalUserFieldAPINames__c, list<String>.class));
                }
            }
            if(listFields.size() > 0){
            	//Dynamic SOQL
	            String SOQL = 'Select ' + String.join(listFields, ',') + ' From Submission__c Where Id = \'' + subRecordId + '\' AND CreatedFromPlan__c = true';
	            List<Submission__c> submissions = Database.query(SOQL);
	            //Check for size
	            if(submissions.size() > 0) {
	            	Submission__c submission = submissions[0];
	            	//Check for required fields
	            	for(String fid : listFields) {
	            		//Check for field value
	            		if(submission.get(fid) == null )
	            			return true;
	            	}	
	            }
	        }
        }
        catch(Exception ex) {
            listFields.add('Id');
            PD_utilityClass.ErrorHandling( 'Apexclass - BB_BuyBoard_PlanController,Method - listAllSelFields', ex.getLineNumber() + ' - ' + ex.getMessage()); 
        }
        return false;
    }
    @AuraEnabled
    public static void changeReviewer(String planId, String reviewerId ) {
    	try{
	    	Plan__c pp = [SELECT Id,Reviewer__c,Sent_To__c FROM Plan__c WHERE id = :planId];
	    	pp.Reviewer__c = reviewerId;
	    	pp.Sent_To__c = reviewerId;
	    	update pp;
    	}
    	catch(Exception ex) {
    		PD_utilityClass.ErrorHandling( 'Apexclass - BB_BuyBoard_PlanController,Method - changeReviewer', ex.getLineNumber() + ' - ' + ex.getMessage()); 
    	}

    }
}