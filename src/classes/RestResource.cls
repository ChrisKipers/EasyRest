@RestResource(urlMapping='/EasyRest/*')
global class RestResource {
	private static String AUTHORIZATION_KEY = 'auth';
	private static String AUTHORIZATION_JUNCTION_KEY = 'auth junc';
	private static String CONFIGURATION_KEY = 'config';
	private static String CONFIGURATION_VERSION_KEY = 'config version';
	private static String TREE_KEY = 'tree';
	@HttpPost
	global static void doPost(){
		Map<String,Object> processedValues = prepService('post');
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		
		Blob rBody = rr.requestBody;
		String body = rBody.toString();
		IsolatedSObjectNode node = (IsolatedSObjectNode)processedValues.get(TREE_KEY);
		//Process string into map or list
		Object params = JSON.deserializeUntyped(body);
		if (params instanceof Map<String,Object>) {
			Map<String,Object> paramsMap = (Map<String,Object>)params;
			SingleNodeResult snr = new SingleNodeResult(node,paramsMap);
			snr.save();
			rs.responseBody = Blob.valueOf(JSON.serialize(snr.buildMap()));
		} else if (params instanceof List<Object>) {
			List<Object> arrayOfParams = (List<Object>)params;
			MultiNodeResult mnr = new MultiNodeResult(node,arrayOfParams);
			mnr.save();
			rs.responseBody = Blob.valueOf(JSON.serialize(mnr.buildArray()));
		}
	}
	
	@HttpGet
	global static void doGet(){
		Map<String,Object> processedValues = prepService('get');
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		List<String> resourceIds = getRestId(rr.requestURI);
		
		if (resourceIds.size() > 0) {
			IsolatedSObjectNode node = (IsolatedSObjectNode)processedValues.get(TREE_KEY);
			if (resourceIds.size() == 0){
				SingleNodeResult result = NodeResult.buildResults(node,resourceIds[0]);
				if (result != null) {
					rs.responseBody = Blob.valueOf(JSON.serialize(result.buildMap()));
				} else {
					rs.statusCode = 404;
				}
			} else {
				MultiNodeResult results = NodeResult.buildResults(node,resourceIds);
				rs.responseBody = Blob.valueOf(JSON.serialize(results.buildArray()));
			}
		}
	}
	
	@HttpDelete
	global static void deleteRecord() {
		Map<String,Object> processedValues = prepService('delete');
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		List<String> resourceIds = getRestId(rr.requestURI);
		if (resourceIds.size() > 0) {
			IsolatedSObjectNode node = (IsolatedSObjectNode)processedValues.get(TREE_KEY);
			if (resourceIds.size() == 1) {
				SingleNodeResult result = NodeResult.buildResults(node,resourceIds[0]);
				if (result != null) {
					result.deleteRecords();
				} else {
					rs.statusCode = 404;
				}
			} else {
				MultiNodeResult results = NodeResult.buildResults(node,resourceIds);
				results.deleteRecords();
			}
		} else {
			rs.statusCode = 404;
		}

		
	}
	
	@HttpPut
	global static void doPut(){
		Map<String,Object> processedValues = prepService('put');
		RestRequest rr = RestContext.request;
		RestResponse rs = RestContext.response;
		Blob rBody = rr.requestBody;
		String body = rBody.toString();
		IsolatedSObjectNode node = (IsolatedSObjectNode)processedValues.get(TREE_KEY);
		Object params = JSON.deserializeUntyped(body);
		
		if (params instanceof Map<String,Object>) {
			Map<String,Object> paramMap = (Map<String,Object>)params;
			List<String> resourceIds = getRestId(rr.requestURI);
			if (resourceIds.size() == 1) {
				SingleNodeResult existingResults = NodeResult.buildResults(node,resourceIds[0]);
				if (existingResults != null) {
					SingleNodeResult updatedResults = new SingleNodeResult(node,paramMap);
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
			MultiNodeResult updatedResults = new MultiNodeResult(node,arrayOfParams);
			List<String> identifiers = new List<String>();
			for (SObjectResult sObjResult: updatedResults.sObjResults) {
				Object identifierValue = sObjResult.obj.get(node.matchingField);
				if (identifierValue != null) {
					String identifier = String.valueOf(identifierValue);
					identifiers.add(identifier);
				}
			}
			MultiNodeResult originalResults = BuildNodeResult.BuildNodeResult(node,identifiers);
			originalResults.mergeResults(updatedResults,true);
			originalResults.save();
			rs.responseBody = Blob.valueOf(JSON.serialize(originalResults.buildArray()));
		}

		
		
	}
	
	private static Receive_Configuration_Version__c getConfiguration(String requestUri) {
		List<String> uriParts = requestUri.split('/');
		String version = uriParts[2];
		String endPointExtension = uriParts[3];
		
		Receive_Configuration_Version__c config = [
													SELECT Active__c, 
													Receive_Configuration__r.Id, Receive_Configuration__r.Active__c, Receive_Configuration__r.Authorization_Header_Key__c , Receive_Configuration__r.Endpoint_Extension__c,
													Receive_Configuration__r.Public_Can_Delete__c ,Receive_Configuration__r.Public_Can_Create__c ,Receive_Configuration__r.Public_Can_Query__c, Receive_Configuration__r.Public_Can_Update__c,
													Schema_Definition__r.Definition__c
													FROM Receive_Configuration_Version__c
													WHERE Receive_Configuration__r.Endpoint_Extension__c = : endPointExtension AND
														Version_Name__c = : version];
														
		return config;
	}
	
	private static Receive_Auth_Key_Junction__c getAuthenticationKey(String key, Receive_Configuration__c configuration) {
		try {
			Receive_Auth_Key_Junction__c junction = [
														SELECT Can_Create__c, Can_Delete__c, Can_Query__c, Can_Update__c, Active__c,
														Authentication_Key__r.Id, Authentication_Key__r.Token__c
														FROM Receive_Auth_Key_Junction__c
														WHERE Authentication_Key__r.Token__c = : key AND
															Receive_Configuration__c = : configuration.id];
			return junction;
		} catch (Exception e) {
		} 
		return null;
	}
	
	private static Map<String, Object> prepService(String opporation) {
		RestRequest rr = RestContext.request;
		Receive_Configuration_Version__c configVersion = getConfiguration(rr.requestURI);
		if (configVersion == null) {
			throw new EndPointDoesNotExistException();
		} else if (!configVersion.Active__c) {
			throw new VersionNotActiveException();
		} else if (!configVersion.Receive_Configuration__r.Active__c) { 
			throw new EndPointNotActiveException();
		}
		String headerKey = rr.headers.get(configVersion.Receive_Configuration__r.Authorization_Header_Key__c);
		Receive_Auth_Key_Junction__c authKeyJunc = null;
		if (String.isNotBlank(headerKey)) {
			authKeyJunc = getAuthenticationKey(headerKey,configVersion.Receive_Configuration__r);
		}
		
		boolean canOpporate = false;
		
		if (opporation == 'post') {
			canOpporate = configVersion.Receive_Configuration__r.Public_Can_Create__c;
		} else if (opporation == 'put') {
			canOpporate = configVersion.Receive_Configuration__r.Public_Can_Update__c;
		} else if (opporation == 'get'){
			canOpporate = configVersion.Receive_Configuration__r.Public_Can_Query__c;
		} else if (opporation == 'delete'){
			canOpporate = configVersion.Receive_Configuration__r.Public_Can_Delete__c;
		}
		
		if (!canOpporate && authKeyJunc != null && authKeyJunc.Active__c) {
			if (opporation == 'post') {
			canOpporate = authKeyJunc.Can_Create__c;
			} else if (opporation == 'put') {
				canOpporate = authKeyJunc.Can_Update__c;
			} else if (opporation == 'get'){
				canOpporate = authKeyJunc.Can_Query__c;
			} else if (opporation == 'delete'){
				canOpporate = authKeyJunc.Can_Delete__c;
			}
		} else if (authKeyJunc != null && !authKeyJunc.Active__c) {
			throw new InActiveAccessTokenException();
		}
		
		if (!canOpporate) {
			throw new NotAuthorizedException();
		}

		List<IsolatedSObjectNode> nodes = NodeTreeConstructor.constructNodeTree(configVersion.Schema_Definition__r.Definition__c);
		
		Map<String,Object> objectMap = new Map<String,Object>{
			AUTHORIZATION_JUNCTION_KEY => authKeyJunc,
			CONFIGURATION_KEY => configVersion.Receive_Configuration__r,
			CONFIGURATION_VERSION_KEY => configVersion,
			TREE_KEY => nodes[0]
		};
		
		if (authKeyJunc != null) {
			objectMap.put(AUTHORIZATION_KEY,authKeyJunc.Authentication_Key__r);
		}
		
		return objectMap;
		
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
	
	public class NotAuthorizedException extends Exception{}
	public class EndPointDoesNotExistException extends Exception{}
	public class EndPointNotActiveException extends Exception{}
	public class VersionDoesNotException extends Exception{}
	public class VersionNotActiveException extends Exception{}
	public class InActiveAccessTokenException extends Exception{}
}