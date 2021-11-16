public inherited sharing class ContentVersionSelector {
    public static Map<Id, ContentVersion> mapContentVersionById;
    public static List<ContentVersion> listContentVersion;
    
    /**
    * @description 
    * @author Deepak Pal | 11-09-2021 
    * @param Set<Id> documentIds 
    * @param Boolean reQuery 
    * @return Map<Id, ContentVersion> 
    **/
    public static Map<Id, ContentVersion> getContentVersionByDocumentIds(Set<Id> documentIds, Boolean reQuery)
    {
        if(!reQuery && mapContentVersionById !=null && !mapContentVersionById.isEmpty()){
            return mapContentVersionById;
        }
        listContentVersion = [
            SELECT Id, VersionData, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :documentIds
        ];
        mapContentVersionById = new Map<Id, ContentVersion>();
        for(ContentVersion cv: listContentVersion){
            mapContentVersionById.put(cv.Id, cv);
        }
        return mapContentVersionById;
    }
    
}