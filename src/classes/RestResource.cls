@RestResource(urlMapping='/EasyRest/*')
global class RestResource {
	@HttpPost
	global static void doPost(){
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		Rest_Schema__c schema = getRestResource(rr.requestURI);
		
		Blob rBody = rr.requestBody;
		String body = rBody.toString();
		
		//Process string into map or list
		Map<String,Object> params = (Map<String,Object>)JSON.deserializeUntyped(body);
		List<IsolatedSObjectNode> nodes = NodeTreeConstructor.constructNodeTree(schema.Schema_Definition__c);
		SingleNodeResult snr = new SingleNodeResult(nodes[0],params);
		snr.save();
		rs.responseBody = Blob.valueOf(JSON.serialize(snr.buildMap()));
	}
	
	@HttpGet
	global static void doGet(){
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		Rest_Schema__c schema = getRestResource(rr.requestURI);
		String resourceId = getRestId(rr.requestURI);
		List<IsolatedSObjectNode> nodes = NodeTreeConstructor.constructNodeTree(schema.Schema_Definition__c);
		SingleNodeResult result = NodeResult.buildResults(nodes[0],resourceId);
		rs.responseBody = Blob.valueOf(JSON.serialize(result.buildMap()));
	}
	
	@HttpDelete
	global static void deleteRecord() {
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		Rest_Schema__c schema = getRestResource(rr.requestURI);
		String resourceId = getRestId(rr.requestURI);
		List<IsolatedSObjectNode> nodes = NodeTreeConstructor.constructNodeTree(schema.Schema_Definition__c);
		SingleNodeResult result = NodeResult.buildResults(nodes[0],resourceId);
		result.deleteRecords();
	}
	
	private static Rest_Schema__c getRestResource(String requestUri) {
		List<String> uriParts = requestUri.split('/');
		String version = uriParts[2];
		String endPointExtension = uriParts[3];
		
		Rest_Schema__c schema = [
			SELECT Id, Schema_Definition__c, Rest_Resource__r.Endpoint_Extention__c, Rest_Resource__r.Id
			FROM Rest_Schema__c
			WHERE Version_Name__c = : version AND 
				Rest_Resource__r.Endpoint_Extention__c = : endPointExtension AND
				Active__c = : true AND Rest_Resource__r.Active__c = : true
			LIMIT 1
		];
	
		
		return schema;
	}
	
	private static String getRestId(String uri) {
		List<String> uriParts = uri.split('/');
		return uriParts[uriParts.size() - 1];
	}
}