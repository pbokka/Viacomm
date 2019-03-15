public class AENotificationHelper {
    
    public static void AEHelper(List<Submission__c> SubMap, Map<Id, Submission__c> mapOldSubmission){
        List<Submission__c> SubList =  new List<Submission__c>();
        for(Submission__c s : SubMap){
           // if(s.Sample_Received__c != null || s.Date_Received__c != null || !String.isBlank(s.Received_By_1__c) ){
               if(s.Samples_Received__c!= mapOldSubmission.get(s.Id).Samples_Received__c|| s.Date_Received__c!= mapOldSubmission.get(s.Id).Date_Received__c||  s.Received_By_1__c != mapOldSubmission.get(s.Id).Received_By_1__c){
                    SubList.add(s);
               } 
           // }   
        }
        if(!SubList.isEmpty()){
            if(AENotification.isOnce == true){
               AENotification.AENotify(SubMap,mapOldSubmission);
            }
        }
        //Testing Apex Classes
    }
}