@RestResource(urlMapping='/EasyRest/*')
global class RestResource {
	@HttpPost
	global static void doPost(){
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		Rest_Schema__c schema = getRestResource(rr.requestURI);
		
		Blob rBody = rr.requestBody;
		String body = rBody.toString();
		List<IsolatedSObjectNode> nodes = NodeTreeConstructor.constructNodeTree(schema.Schema_Definition__c);
		//Process string into map or list
		Object params = JSON.deserializeUntyped(body);
		if (params instanceof Map<String,Object>) {
			Map<String,Object> paramsMap = (Map<String,Object>)params;
			SingleNodeResult snr = new SingleNodeResult(nodes[0],paramsMap);
			snr.save();
			rs.responseBody = Blob.valueOf(JSON.serialize(snr.buildMap()));
		} else if (params instanceof List<Object>) {
			List<Object> arrayOfParams = (List<Object>)params;
			MultiNodeResult mnr = new MultiNodeResult(nodes[0],arrayOfParams);
			mnr.save();
			rs.responseBody = Blob.valueOf(JSON.serialize(mnr.buildArray()));
		}
	}
	
	@HttpGet
	global static void doGet(){
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		Rest_Schema__c schema = getRestResource(rr.requestURI);
		List<String> resourceIds = getRestId(rr.requestURI);
		if (resourceIds.size() > 0) {
			List<IsolatedSObjectNode> nodes = NodeTreeConstructor.constructNodeTree(schema.Schema_Definition__c);
			if (resourceIds.size() == 0){
				SingleNodeResult result = NodeResult.buildResults(nodes[0],resourceIds[0]);
				if (result != null) {
					rs.responseBody = Blob.valueOf(JSON.serialize(result.buildMap()));
				} else {
					rs.statusCode = 404;
				}
			} else {
				MultiNodeResult results = NodeResult.buildResults(nodes[0],resourceIds);
				rs.responseBody = Blob.valueOf(JSON.serialize(results.buildArray()));
			}
		}
	}
	
	@HttpDelete
	global static void deleteRecord() {
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		Rest_Schema__c schema = getRestResource(rr.requestURI);
		List<String> resourceIds = getRestId(rr.requestURI);
		if (resourceIds.size() > 0) {
			List<IsolatedSObjectNode> nodes = NodeTreeConstructor.constructNodeTree(schema.Schema_Definition__c);
			if (resourceIds.size() == 1) {
				SingleNodeResult result = NodeResult.buildResults(nodes[0],resourceIds[0]);
				if (result != null) {
					result.deleteRecords();
				} else {
					rs.statusCode = 404;
				}
			} else {
				MultiNodeResult results = NodeResult.buildResults(nodes[0],resourceIds);
				results.deleteRecords();
			}
		} else {
			rs.statusCode = 404;
		}

		
	}
	
	@HttpPut
	global static void doPut(){
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		Blob rBody = rr.requestBody;
		String body = rBody.toString();
		
		Rest_Schema__c schema = getRestResource(rr.requestURI);
		List<IsolatedSObjectNode> nodes = NodeTreeConstructor.constructNodeTree(schema.Schema_Definition__c);
		Object params = JSON.deserializeUntyped(body);
		
		if (params instanceof Map<String,Object>) {
			Map<String,Object> paramMap = (Map<String,Object>)params;
			List<String> resourceIds = getRestId(rr.requestURI);
			if (resourceIds.size() == 1) {
				SingleNodeResult existingResults = NodeResult.buildResults(nodes[0],resourceIds[0]);
				if (existingResults != null) {
					SingleNodeResult updatedResults = new SingleNodeResult(nodes[0],paramMap);
					existingResults.mergeResults(updatedResults);
					existingResults.save();
					rs.responseBody = Blob.valueOf(JSON.serialize(existingResults.buildMap()));
				} else {
					rs.statusCode = 404;
				}
			} else {
				rs.statusCode = 404;
			}
		} else if (params instanceof List<Object>) {
			List<Object> arrayOfParams = (List<Object>)params;
			MultiNodeResult updatedResults = new MultiNodeResult(nodes[0],arrayOfParams);
			List<String> identifiers = new List<String>();
			for (SObjectResult sObjResult: updatedResults.sObjResults) {
				Object identifierValue = sObjResult.obj.get(nodes[0].matchingField);
				if (identifierValue != null) {
					String identifier = String.valueOf(identifierValue);
					identifiers.add(identifier);
				}
			}
			MultiNodeResult originalResults = BuildNodeResult.BuildNodeResult(nodes[0],identifiers);
			originalResults.mergeResults(updatedResults,true);
			originalResults.save();
			rs.responseBody = Blob.valueOf(JSON.serialize(originalResults.buildArray()));
		}

		
		
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
	
	private static List<String> getRestId(String uri) {
		List<String> uriParts = uri.split('/');
		String idToken = uriParts[uriParts.size() - 1];
		List<String> allIds = idToken.split('&');
		List<String> urldecodedIds = new List<String>();
		for (String encodedUrl : allIds) {
			//urldecodedIds.add(EncodingUtil.urlDecode(encodedUrl));
			urldecodedIds.add(encodedUrl);
		}
		return urldecodedIds;
	}
}