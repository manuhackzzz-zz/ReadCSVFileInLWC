public inherited sharing class CLMParseCSVToPEController {

    @AuraEnabled
    public static LightningResponse parseCsvToPe(String recordId, String filesJson){
        try {
            System.debug('---------------------Entered------------------');
            Opportunity oppRecord = 
            OpportunitySelector.getOpportunitiesById(new Set<Id>{recordId}, true).get(recordId);
            
            Map<String, CLMParseCSVToPEHelper.FieldInformationWrapper> mapFieldInfoWrapperByLabel = 
                CLMParseCSVToPEHelper.getOppFieldsMetadata(oppRecord);

            List<CLMParseCSVToPEHelper.FileWrapper> uploadedFiles = 
                (List<CLMParseCSVToPEHelper.FileWrapper>)JSON.deserialize(filesJson, List<CLMParseCSVToPEHelper.FileWrapper>.class);
            system.debug('uploadedFiles: '+uploadedFiles);

            Set<Id> documentIds = CLMParseCSVToPEHelper.getDocumentIdSet(uploadedFiles);

            Map<Id, ContentVersion> mapContentVersionByContentVersionId = 
                ContentVersionSelector.getContentVersionByDocumentIds(documentIds, true);

            Map<Id, ContentVersion> mapContentVersionByContentDocumentId = 
                CLMParseCSVToPEHelper.getContentVersionByDocumentIds(mapContentVersionByContentVersionId);

            Map<Id, List<String>> mapRowDataByDocumentId = 
                CLMParseCSVToPEHelper.getRowDataFromDocuments(mapContentVersionByContentDocumentId);

            List<CLMParseCSVToPEHelper.PEDataWrapper> listPEDataWrapper = 
                CLMParseCSVToPEHelper.getPEDataFromContentVersion(
                    mapRowDataByDocumentId, mapFieldInfoWrapperByLabel,oppRecord
                );

            if(!listPEDataWrapper.isEmpty()){
                List<Pricing_Exhibit__c> listForInsert = CLMParseCSVToPEHelper.getListForInsert(listPEDataWrapper);
                List<String> errorList = CLMParseCSVToPEHelper.getListOfErrors(listPEDataWrapper, uploadedFiles);

                if(listForInsert!=null && !listForInsert.isEmpty()){
                    insert listForInsert;
                }

                if(listForInsert.isEmpty()){
                    return new LightningResponse(
                        false, 'ERROR', String.join(errorList, '\n'), 'error',
                        CLMParseCSVToPEHelper.TOAST_STICKY
                    );
                }else if(errorList.isEmpty()){
                    return new LightningResponse(
                        true, 'SUCCESS', 'Records created successfully', 
                        'success', CLMParseCSVToPEHelper.TOAST_DISMISSIBLE
                    );
                }else{
                    return new LightningResponse(
                        true, 'PARTIAL SUCCESS', 'Records creation failed for following=>', 
                        'info', CLMParseCSVToPEHelper.TOAST_STICKY
                    );
                }
            }else{
                return new LightningResponse(
                    true, 'WARNING', 'No data found to insert records', 
                    'warning',CLMParseCSVToPEHelper.TOAST_STICKY
                );
            }

            
        } catch (Exception e) {
            String message = 'Failed to parse the CSV(s). Please give your Administrator the following message: ';
            message += e.getMessage();
            return new LightningResponse(false, 'ERROR', message, 'error', CLMParseCSVToPEHelper.TOAST_STICKY);
        }
    }

    public inherited sharing class LightningResponse{
        @AuraEnabled public Boolean success;
        @AuraEnabled public String title;
        @AuraEnabled public String message;
        @AuraEnabled public String variant;
        @AuraEnabled public String mode;

        public LightningResponse(Boolean success, String title, String message, String variant, String mode){
            this.success = success;
            this.title = title;
            this.message = message;
            this.variant = variant;
            this.mode = mode;
        }
    }
}