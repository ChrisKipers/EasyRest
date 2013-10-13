public with sharing class SchemaBuilderController {
	public Rest_Schema__c schema {get; set;}
	@RemoteAction
	public static List<Map<String,String>> getFieldsForObject(String sObjectType) {
		List<Map<String,String>> results = new List<Map<String,String>>();
		for (Schema.DescribeFieldResult dfr: DynamicHelper.getAllFields(sObjectType)) {
			Map<String,String> obj = new Map<String,String>();
			obj.put('name',dfr.getName());
			obj.put('label',dfr.getLabel());
			obj.put('type', String.valueOf(dfr.getType()));
			results.add(obj);
		}
		return results;
	}
	
	@RemoteAction
	public static List<Map<String,String>> getFieldsForObjectLookup(String apiName, String sObjectType) {
		String childSObjectType = DynamicHelper.getLookupSObjectType(apiName,sObjectType);
		return getFieldsForObject(childSObjectType);
	}
	
	@RemoteAction
	public static List<Map<String,String>> getAllSObjectsInOrg() {
		List<Map<String,String>> results = new List<Map<String,String>>();
		for (Schema.SObjectType sObjType : DynamicHelper.getAllSObjectsInOrg()) {
			Schema.Describesobjectresult dsr = sObjType.getDescribe();
			
			Map<String,String> obj = new Map<String,String>();
			obj.put('name',dsr.getName());
			obj.put('label',dsr.getLabel());
			results.add(obj);
		}
		return results;
	}
	
	@RemoteAction
	public static List<Map<String,String>> getAllChildren(String sObjectType) {
		List<Map<String,String>> results = new List<Map<String,String>>();
		List<Schema.ChildRelationship> children = DynamicHelper.getAllRelatedObjects(sObjectType);
		for (Schema.ChildRelationship childType : children) {
			Schema.Describesobjectresult dsr = childType.getChildSObject().getDescribe();
			
			Map<String,String> obj = new Map<String,String>();
			obj.put('name',dsr.getName());
			obj.put('label',dsr.getLabel());
			obj.put('relationKey',childType.getField().getDescribe().getName());
			results.add(obj);
		}
		return results;
	}
	
	@RemoteAction
	public static String getSObjectType(String apiName, String parentSObjectType) {
		return DynamicHelper.getLookupSObjectType(apiName,parentSObjectType);
	}
	
	@RemoteAction
	public static String getFieldsForRelationObject(String apiName, String parentObject) {
		return null;
	}
	
	public SchemaBuilderController(ApexPages.StandardController controller) {
		Id schemaId = controller.getId();
		if (schemaId != null) {
			List<Rest_Schema__c> schemas = (List<Rest_Schema__c>)DynamicHelper.queryAllFields('Rest_Schema__c', 'id', String.valueOf(schemaId));
			if (schemas.size() == 1) {
				schema = schemas[0];
				
				//Compress json
				if (String.isNotBlank(schema.Schema_Definition__c)) {
					Object jsonObj = JSON.deserializeUntyped(schema.Schema_Definition__c);
					schema.Schema_Definition__c = JSON.serialize(jsonObj);
				}
			}
		}
		if (schema == null) {
			schema = new Rest_Schema__c();
		}
	}
	public void submitSchema() {
		System.debug(schema.Schema_Definition__c);
		upsert schema;
	}
}