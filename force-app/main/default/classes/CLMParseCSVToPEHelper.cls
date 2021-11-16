public inherited sharing class CLMParseCSVToPEHelper {

    public static FINAL String COLUMNS_MISSING = 'ColumnsMissing';
    public static FINAL String TOAST_DISMISSIBLE = 'dismissible';
    public static FINAL String TOAST_STICKY = 'sticky';
    
    public static Map<String, FieldInformationWrapper> getOppFieldsMetadata(Opportunity oppRecord){
        PEOpportunityType__mdt oppTypeMetadta = 
            PEOpportunityType__mdt.getInstance(oppRecord.clm_request_type_picklist__c.replaceAll(' ','_'));
        if(oppTypeMetadta == null){
            throw new NoCustomMetadataMappingException(
                'Please check custom metadata mapping (PEOpportunityType__mdt) for Request Type \''
                +oppRecord.clm_request_type_picklist__c
                +'\''
            );
        }
        List<PETypeFieldMapping__mdt> listTypeFieldMapping = [
            SELECT 
            ID, OpportunityType__c, Field__c, Required__c, Field__r.MasterLabel, 
            Field__r.DataType__c, Field__r.DefaultValue__c, Field__r.FieldAPIName__c
            FROM PETypeFieldMapping__mdt
            WHERE OpportunityType__c = :oppTypeMetadta.Id
        ];
        if(listTypeFieldMapping == null || listTypeFieldMapping.isEmpty()){
            throw new NoCustomMetadataMappingException(
                'Please check custom metadata mapping (PETypeFieldMapping__mdt) for Request Type \''
                +oppRecord.clm_request_type_picklist__c
                +'\''
            );
        }
        Map<String, FieldInformationWrapper> mapFieldInfoWrapperByLabel = getFieldInformationWrapperList(listTypeFieldMapping);
        return mapFieldInfoWrapperByLabel;
    }
    
    /**
* @description 
* @author Deepak Pal | 11-09-2021 
* @param List<PETypeFieldMapping__mdt> listTypeFieldMapping 
* @return Map<Id, FieldInformationWrapper>
**/
    public static Map<String, FieldInformationWrapper> getFieldInformationWrapperList(
        List<PETypeFieldMapping__mdt> listTypeFieldMapping
    ){
        Map<String, FieldInformationWrapper> mapFieldInfoWrapperByLabel = new Map<String, FieldInformationWrapper>();
        for(PETypeFieldMapping__mdt peTypeFieldMapping: listTypeFieldMapping){
            mapFieldInfoWrapperByLabel.put(
                peTypeFieldMapping.Field__r.MasterLabel,
                new FieldInformationWrapper(
                    peTypeFieldMapping.Field__c,
                    peTypeFieldMapping.Field__r.MasterLabel,
                    peTypeFieldMapping.Field__r.FieldAPIName__c,
                    peTypeFieldMapping.Required__c,
                    peTypeFieldMapping.Field__r.DefaultValue__c,
                    peTypeFieldMapping.Field__r.DataType__c
                )
            );
        }
        return mapFieldInfoWrapperByLabel;
    }
    
    /**
* @description 
* @author Deepak Pal | 11-09-2021 
* @param List<FileWrapper> files 
* @return Set<Id> 
**/
    public static Set<Id> getDocumentIdSet(List<FileWrapper> files){
        Set<Id> contentDocumentIDs = new Set<Id>();
        for(FileWrapper file: files){
            contentDocumentIDs.add(file.documentId);
        }
        return contentDocumentIDs;
    }
    
    /**
* @description 
* @author Deepak Pal | 11-09-2021 
* @param Map<Id ContentVersion> mapContentVersionByContentVersionId 
* @return Map<Id, ContentVersion> 
**/
    public static Map<Id, ContentVersion> getContentVersionByDocumentIds(
        Map<Id, ContentVersion> mapContentVersionByContentVersionId
    ){
        Map<Id, ContentVersion> mapContentVersionByDocumentId = new Map<Id, ContentVersion>();
        for(ContentVersion cv: mapContentVersionByContentVersionId.values()){
            mapContentVersionByDocumentId.put(cv.ContentDocumentId, cv);
        }
        return mapContentVersionByDocumentId;
    }
    
    /**
* @description 
* @author Deepak Pal | 11-09-2021 
* @param Map<Id ContentVersion> mapContentVersionByContentDocumentId 
* @return Map<Id, Set<String>> 
**/
    public static Map<Id, List<String>> getRowDataFromDocuments(
        Map<Id, ContentVersion> mapContentVersionByContentDocumentId
    ){
        Map<Id, List<String>> mapRowDataByDocumentId = new Map<Id, List<String>>();
        for(Id documentId: mapContentVersionByContentDocumentId.keySet()){
            ContentVersion contentVersion = mapContentVersionByContentDocumentId.get(documentId);
            String stringContent = contentVersion.VersionData.toString();
            stringContent = stringContent.replaceAll('\r\n', '\n');
            List<String> rowData = stringContent.split('\n');
            mapRowDataByDocumentId.put(documentId, rowData);
        }
        return mapRowDataByDocumentId;
    }
    
    /**
* @description 
* @author Deepak Pal | 11-09-2021 
* @param Map<Id List<String>> mapRowDataByDocumentId 
* @return List<PEDataWrapper> 
**/
 /*   public static List<PEDataWrapper> getPEDataFromContentVersion(Map<Id, List<String>> mapRowDataByDocumentId){
        List<PEDataWrapper> listPEDataWrapper = new List<PEDataWrapper>();
        for(Id documentId: mapRowDataByDocumentId.keySet()){
            List<String> fileData = mapRowDataByDocumentId.get(documentId);
            Set<String> headerdata = getHeaderFromFileData(fileData[0]);
            
        }
        return listPEDataWrapper;
    }*/
    
    /**
* @description 
* @author Deepak Pal | 11-09-2021 
* @param String header 
* @return Set<String> 
**/
    public static Set<String> getHeaderFromFileData(String header){
        Set<String> headerData = new Set<String>();
        headerData.addAll(header.split(','));
        return headerData;
    }
    
    /**
* @description 
* @author Deepak Pal | 11-09-2021 
* @param Map<Id List<String>> mapRowDataByDocumentId 
* @param mapRowDataByDocumentIdMap<Id FieldInformationWrapper> mapFieldInfoWrapperByLabel 
* @return List<PEDataWrapper> 
**/
    
    public static List<PEDataWrapper> getPEDataFromContentVersion(
        Map<Id, List<String>> mapRowDataByDocumentId, 
        Map<String, FieldInformationWrapper> mapFieldInfoWrapperByLabel,
        Opportunity oppRecord
    ){
        List<PEDataWrapper> listPEDataWrapper = new List<PEDataWrapper>();
        for(Id documentId: mapRowDataByDocumentId.keySet()){
            listPEDataWrapper.add(
                createPEDataWrapper(
                    documentId, 
                    mapRowDataByDocumentId.get(documentId), 
                    mapFieldInfoWrapperByLabel,
                    oppRecord
                )
            );
        }
        return listPEDataWrapper;
    }
    
    /**
* @description 
* @author Deepak Pal | 11-09-2021 
* @param List<String> fileRowsData 
* @param Map<String FieldInformationWrapper> mapFieldInfoWrapperByLabel 
* @return PEDataWrapper 
**/
    public static PEDataWrapper createPEDataWrapper(
        Id documentId,
        List<String> fileRowsData,
        Map<String, FieldInformationWrapper> mapFieldInfoWrapperByLabel,
        Opportunity oppRecord
    ){
        PEDataWrapper peDataWrapper;
        List<String> headerDataList = fileRowsData[0].split(',');
        Set<String> headerDataSet = new Set<String>(headerDataList);
        //Set<String> headerDataSet = getTrimmedLabels(headerDataList);
        
        List<Object> checkHeaderValidity = getHeaderValidity(headerDataSet, mapFieldInfoWrapperByLabel.values());
        if(!(Boolean)checkHeaderValidity[0]){
            peDataWrapper = new PEDataWrapper(documentId,false,null,COLUMNS_MISSING,(String)checkHeaderValidity[1]);
            return peDataWrapper;
        }
        Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Pricing_Exhibit__c.fields.getMap();
        try{
            List<Pricing_Exhibit__c> listPricingExibit = new List<Pricing_Exhibit__c>();
            for(Integer i=1; i< fileRowsData.size(); i++){
                Pricing_Exhibit__c peExibit = new Pricing_Exhibit__c();
                List<String> rowColumnData = fileRowsData[i].split(',');
                for(Integer j=0; j<rowColumnData.size(); j++){
                    String fieldLabel = headerDataList[j];
                    if(mapFieldInfoWrapperByLabel.containsKey(fieldLabel)){
                        String fieldApiName = mapFieldInfoWrapperByLabel.get(fieldLabel).fieldApiName;
                        if(!fieldMap.get(fieldApiName).getDescribe().isCreateable()){
                            throw new NoCreatePermissionException(
                                'User does not have create permission for \''+ fieldLabel +'\' field'
                            );
                        }
                        String rowColumnDataStr;
                        if(String.isBlank(rowColumnData[j])){
                            rowColumnDataStr = mapFieldInfoWrapperByLabel.get(fieldLabel).defaultValue;
                        }else{
                            rowColumnDataStr = rowColumnData[j];
                        }
                        Object value = getFieldValue(fieldMap.get(fieldApiName), rowColumnDataStr);
                        peExibit.put(fieldApiName, value);
                    }
                }
                peExibit.clm_opportunity_lookup__c = oppRecord.Id;
                peExibit.clm_account_lookup__c = oppRecord.AccountId;
                listPricingExibit.add(peExibit);
            }
            peDataWrapper = new PEDataWrapper(documentId,true,listPricingExibit,null,null);
        }catch(Exception e){
            peDataWrapper = new PEDataWrapper(documentId,false,null,'Exception','Parsing error. message: '+e.getMessage());
            return peDataWrapper;
        }
        return peDataWrapper;
    }

    /**
    * @description 
    * @param List<String> headerDataList 
    * @return Set<String> 
    **/
    public static Set<String> getTrimmedLabels(List<String> headerDataList){
        Set<String> headerDataSet = new Set<String>();
        for(String headerData: headerDataList){
            headerDataSet.add(headerData.trim());
        }
        return headerDataSet;
    }
    
    public static List<Object> getHeaderValidity(
        Set<String> headerDataSet,
        List<FieldInformationWrapper> listFieldInfo
    ){
        List<Object> returnVar = new List<Object>();
        List<String> missingColumns = new List<String>();
        Boolean isValid = true;
        for(FieldInformationWrapper fieldInfo: listFieldInfo){
            if(fieldInfo.required && !headerDataSet.contains(fieldInfo.fieldLabel)){
                missingColumns.add(fieldInfo.fieldLabel);
                isValid = false;
            }
        }
        returnVar.add(isValid);
        if(!isValid){
            String message = 'Missing columns: '+String.join(missingColumns, ',')+'.';
            returnVar.add(message);
        }
        return returnVar;
    }
    
    public static Object getFieldValue(Schema.SObjectField fieldResult, String strValue){
        Schema.DisplayType fieldType = fieldResult.getDescribe().getType();
        switch on fieldType {
            when Currency, Percent, Double{
                return Decimal.valueOf(strValue);
            }
            when Boolean{
                return Boolean.valueOf(strValue);
            }
            
            when Date{
                return Date.valueOf(strValue);
            }
            when DateTime{
                return DateTime.valueOf(strValue);
            }
            
            when Long{
                return Long.valueOf(strValue);
            }
            when Integer{
                return Integer.valueOf(strValue);
            }
            when URL, TextArea, String, Picklist, MultiPicklist, Email, Combobox, Phone{
                return String.valueOf(strValue);
            }
           // when Time{
           //     return Time.valueOf(strValue);
           // }
        }
        return strValue;
    }
    
    public static List<Pricing_Exhibit__c> getListForInsert(List <PEDataWrapper> listPEDataWrapper)
    {
        List<Pricing_Exhibit__c> recordsToBeInserted = new List<Pricing_Exhibit__c>();
        for(PEDataWrapper peDataWrapper: listPEDataWrapper)
        {
            if(peDataWrapper.success){
                recordsToBeInserted.addAll(peDataWrapper.listPricingExibit);
            }
        }
        return recordsToBeInserted;
    }
    
    public static List<String> getListOfErrors(List <PEDataWrapper> peDataWrapper, List <FileWrapper> uploadedFiles)
    {
        List<String> errorList = new List<String>();
        Map<String, String> filesMap = new Map<String, String>();
        for(FileWrapper file: uploadedFiles)
        {
            filesMap.put(file.documentId, file.name);
        }
        
        for(PEDataWrapper pe: peDataWrapper)
        {
            if(!pe.success)
            {
                errorList.add('Error on file \''+filesMap.get(pe.documentId)+'\'. '+pe.errorMessage);
            }
        }
        return errorList;
    }
    
    public class NoCustomMetadataMappingException extends Exception {}
    public class NoCreatePermissionException extends Exception {}
    
    public inherited sharing class FileWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String documentId;
        @AuraEnabled public String contentVersionId;  
        
        public FileWrapper(String name, String documentId, String contentVersionId){
            this.name = name;
            this.documentId = documentId;
            this.contentVersionId = contentVersionId;
        }
    }
    
    public inherited sharing class PEDataWrapper{
        public String documentId;
        public Boolean success;
        public List<Pricing_Exhibit__c> listPricingExibit;
        public String errorType;
        public String errorMessage;
        
        public PEDataWrapper(
            String documentId, 
            Boolean success, 
            List<Pricing_Exhibit__c> listPricingExibit, 
            String errorType,
            String errorMessage
        ){
            this.documentId = documentId;
            this.success = success;
            this.errorType = errorType;
            this.listPricingExibit = listPricingExibit;
            this.errorMessage = errorMessage;
        }
    }
    
    public inherited sharing class FieldInformationWrapper{
        public Id metadataId;
        public String fieldLabel;
        public String fieldApiName;
        public Boolean required;
        public String defaultValue;
        public String dataType;
        
        public FieldInformationWrapper(
            Id metadataId,
            String fieldLabel,
            String fieldApiName,
            Boolean required,
            String defaultValue,
            String dataType
        ){
            this.metadataId = metadataId;
            this.fieldLabel = fieldLabel;
            this.fieldApiName = fieldApiName;
            this.required = required;
            this.defaultValue = defaultValue;
            this.dataType = dataType;
        }
    }
}