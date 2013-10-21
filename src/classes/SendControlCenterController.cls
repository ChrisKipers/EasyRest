public with sharing class SendControlCenterController {
	public Send_Configuration__c 		config 					{get; set;}
	public Id							selectedInteractionId	{get; set;}
	public Send_Interaction__c 			selectedInteraction 	{get; set;}
	public Map<id, Send_Interaction__c>	allInteractions			{get; set;}
	public Map<id, List<Header__c>>		allHeaders				{get; set;}
	public List<Header__c>				activeHeaders			{get; set;}
	public List<SelectOption>			interactionOptions		{get; set;}
	public Schema_Definition__c			sendSchema				{get; set;}
	public Schema_Definition__c			receiveSchema			{get; set;}
	public List<Identifier>				identifierIds			{get; set;}
	public String						requestBody				{get; set;}
	public String						responseBody			{get; set;}
	public String						endPoint				{get; set;}
	public String						respStatus				{get; set;}
	
	public SendControlCenterController(ApexPages.StandardController controller) {
		config = (Send_Configuration__c)DynamicHelper.queryAllFields('Send_Configuration__c', 'id', String.valueOf(controller.getId()))[0];
		List<Send_Interaction__c> interactions = (List<Send_Interaction__c>)DynamicHelper.queryAllFields('Send_Interaction__c', 'Send_Configuration__c', String.valueOf(config.id));
		interactionOptions = new List<SelectOption>();
		allInteractions = new Map<id, Send_Interaction__c>();
		List<String> allInteractionIds = new List<String>();
		for (Send_Interaction__c interaction : interactions) {
			allInteractions.put(interaction.id, interaction);
			interactionOptions.add( new SelectOption(interaction.id, interaction.Name + ' / ' + interaction.Action__c));
			allInteractionIds.add(interaction.id);
		}
		String interactionParam = ApexPages.currentPage().getParameters().get('interactionId');
		if (String.isNotBlank(interactionParam)) {
			Id interactionId = DynamicHelper.convertToId(interactionParam);
			selectedInteraction = allInteractions.get(interactionId);
		}
		activeHeaders = new List<Header__c>();
		allHeaders = new Map<id, List<Header__c>>();
		List<Header__c> headers = (List<Header__c>)DynamicHelper.queryAllFields('Header__c', 'Send_Interaction__c', allInteractionIds);
		for (Header__c header : headers) {
			List<Header__c> intercationHeaders = allHeaders.get(header.Send_Interaction__c);
			if (intercationHeaders == null) {
				intercationHeaders = new List<Header__c>();
				allHeaders.put(header.Send_Interaction__c, intercationHeaders);
			}
			intercationHeaders.add(header);
		}
		
		identifierIds = new List<identifier>();
		
		if (selectedInteraction == null) {
			if (allInteractions.size() > 0) {
				selectedInteraction = allInteractions.values()[0];
				selectedInteractionId = selectedInteraction.Id;
			}
		}
		if (selectedInteraction != null) {
			setInteraction();
		}
	}
	
	public void setInteraction() {
		activeHeaders.clear();
		responseBody = null;
		if ( selectedInteractionId == null) {
			sendSchema = null;
			receiveSchema = null;
			requestBody = null;
			endPoint = null;
		} else {
			selectedInteraction = allInteractions.get(selectedInteractionId);
			endPoint = selectedInteraction.Endpoint__c;
			List<Header__c> interactionHeaders = allHeaders.get(selectedInteraction.id);
			if (interactionHeaders != null) {
				activeHeaders.addAll(interactionHeaders);
			}
			
			if (selectedInteraction.Send_Schema__c != null) {
				sendSchema = (Schema_Definition__c)DynamicHelper.queryAllFields('Schema_Definition__c', 'id', String.valueOf(selectedInteraction.Send_Schema__c))[0];
			}
			
			if (selectedInteraction.Receive_Schema__c != null) {
				receiveSchema = (Schema_Definition__c)DynamicHelper.queryAllFields('Schema_Definition__c', 'id', String.valueOf(selectedInteraction.Receive_Schema__c))[0];
			} else {
				receiveSchema = null;
			}
			
			updateIdentifiers();
		}
	}
	
	public List<String> filterIds() {
		List<String> realIds = new List<String>();
		for (Identifier identifier : identifierIds) {
			if (identifier.value != null && (identifier.value.length() == 15 || identifier.value.length() == 18)) {
				realIds.add(identifier.value);
			}
		}
		
		return realIds;
	}
	
	public void updateIdentifiers() {
		updateRequestBody();
	}
	
	public void updateMatchingIds(String matchingFieldValue) {
		if (String.isNotBlank(matchingFieldValue)) {
			updateMatchingIds(new List<String>{matchingFieldValue});
		}
	}
	
	public void updateMatchingIds(List<string> matchingFieldValues) {
		if (matchingFieldValues != null) {
			List<String> urlEncodedMatchingFields = new List<String>();
			for (String matchingField : matchingFieldValues) {
				urlEncodedMatchingFields.add(EncodingUtil.urlEncode(matchingField,'UTF-8'));
			}
			endPoint =  selectedInteraction.Endpoint__c + '/' + String.join(urlEncodedMatchingFields,'&');
		} else {
			endPoint = selectedInteraction.Endpoint__c;
		}
		System.debug('new endpoint: ' + endpoint);
	}

	public void updateRequestBody() {
		List<SObjectResult> allSObjectResults = new List<SObjectResult>();
		List<String> realIds = filterIds();
		if (sendSchema != null && realIds.size() > 0) {
			IsolatedSObjectNode tree =  NodeTreeConstructor.constructNodeTree(sendSchema.Definition__c)[0];
			if (identifierIds.size() == 1 ) {
				SingleNodeResult snr = NodeResult.buildResultsBySFId(tree,realIds[0]);
				if (selectedInteraction.Add_Matching_Fields__c) {
					updateMatchingIds(snr.getMatchingFieldValue());
				}
				Map<String, Object> mapping = snr.buildMap();
				requestBody = JSON.serialize(mapping);
			} else {
				MultiNodeResult mnr = NodeResult.buildResultsBySFId(tree,realIds);
				if (selectedInteraction.Add_Matching_Fields__c) {
					updateMatchingIds(mnr.getMatchingFieldValues());
				}
				List<Object> results = mnr.buildArray();
				requestBody = JSON.serialize(results);
			}
			if (!selectedInteraction.Add_Matching_Fields__c) {
				endPoint = selectedInteraction.Endpoint__c;
			}
		} else {
			requestBody = null;
		}
	}
	
	public void addHeader() {
		activeHeaders.add(new Header__c());
	}
	
	public Integer removeHeaderIndex {get; set;}
	public void removeHeader() {
		if (removeHeaderIndex != null && removeHeaderIndex < activeHeaders.size()) {
			activeHeaders.remove(removeHeaderIndex);
		}
	}
	
	public void addIdentifier() {
		identifierIds.add(new Identifier());
	}
	
	public Integer removeIdentifierId	{get; set;}
	public void removeIdentifier() {
		if (removeIdentifierId != null && removeIdentifierId < identifierIds.size()) {
			identifierIds.remove(removeIdentifierId);
			updateRequestBody();
		}
	}
	
	public class Identifier {
		public String value 	{get; set;}
	}
	
	public void makeRequest() {
		HttpRequest req = new HttpRequest();
		req.setEndpoint(endPoint);
		for (Header__c head : activeHeaders) {
			req.setHeader(head.Key__c, head.Value__c);
		}
		if (String.isNotBlank(requestBody)) {
			req.setBody(requestBody);
		}
		
		req.setHeader('Content-Type','application/json');
		
		String action = selectedInteraction.Action__c;
		if (action == 'Create') {
			req.setMethod('POST');
		} else if (action == 'Update') {
			req.setMethod('PUT');
		} else if (action == 'Delete') {
			req.setMethod('DELETE');
		} else if (action == 'Query') {
			req.setMethod('GET');
		}
		Http sender = new Http();
		HttpResponse res = sender.send(req);
		responseBody = res.getBody();
		respStatus = res.getStatus();
	}
	
	public void saveResponse() {
		if (receiveSchema != null) {
			IsolatedSObjectNode tree =  NodeTreeConstructor.constructNodeTree(receiveSchema.Definition__c)[0];
			if (selectedInteraction.Link_Records__c) {
				if (identifierIds.size() == 1) {
					SingleNodeResult oldSnr = NodeResult.buildResultsBySFId(tree, identifierIds[0].value);
					Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
					SingleNodeResult newSnr = new SingleNodeResult(tree,results);
					oldSnr.mergeResults(newSnr);
					oldSnr.save();
				} else if (identifierIds.size() > 1){
					List<String> ids = new List<String>();
					for (Identifier ident : identifierIds) {
						if (String.isNotBlank(ident.value)) {
							ids.add(ident.value);
						}
					}
					MultiNodeResult oldMnr = NodeResult.buildResultsBySFId(tree, ids);
					List<Object> results = (List<Object>)JSON.deserializeUntyped(responseBody);
					MultiNodeResult newMnr = new MultiNodeResult(tree,results);
					oldMnr.mergeResults(newMnr);
					oldMnr.save();	
				}
			} else {
				Object responseResult = (Object)JSON.deserializeUntyped(responseBody);
				if (responseResult instanceof List<Object>) {
					List<Object> newRecords = (List<Object>)responseResult;
					MultiNodeResult newMnr = new MultiNodeResult(tree,newRecords);
					newMnr.save();
				} else if (responseResult instanceof Map<String, Object>) {
					Map<String, Object> newRecord = (Map<String, Object>)responseResult;
					SingleNodeResult newSnr = new SingleNodeResult(tree,newRecord);
					newSnr.save();
				}
			}
		}
	}
}