public with sharing class SchemaBuilderController {
	public Schema_Definition__c schema {get; set;}
	public String previewId				{get; set;}
	public String previewString			{get; set;}

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
			List<Schema_Definition__c> schemas = (List<Schema_Definition__c>)DynamicHelper.queryAllFields('EasyConnect__Schema_Definition__c', 'id', String.valueOf(schemaId));
			if (schemas.size() == 1) {
				schema = schemas[0];
				
				//Compress json
				if (String.isNotBlank(schema.Definition__c)) {
					Object jsonObj = JSON.deserializeUntyped(schema.Definition__c);
					schema.Definition__c = JSON.serialize(jsonObj);
				}
			}
		}
		if (schema == null) {
			schema = new Schema_Definition__c();
		}
	}
	public void submitSchema() {
		System.debug(schema.Definition__c);
		upsert schema;
	}
	
	public void setPreviewString() {
		List<IsolatedSObjectNode> nodes = NodeTreeConstructor.constructNodeTree(schema.Definition__c);
		SingleNodeResult existingResults = NodeResult.buildResultsBySFId(nodes[0],previewId);
		Map<String, Object> results = existingResults.buildMap();
		previewString = JSON.serialize(results);
	}
}