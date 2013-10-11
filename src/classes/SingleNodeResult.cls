public class SingleNodeResult extends NodeResult {
	public SObject obj	{get; set;}
	public List<NodeResult> childrenResults	{get; set;}
	public Set<String> fieldsIncludedInRequest {get; set;}
	
	/******************** Methods used to construct node from SObject ***************/
	public SingleNodeResult(SObjectNode nodep) {
		node = nodep;
		childrenResults = new List<NodeResult>();
		fieldsIncludedInRequest = new Set<String>();
	}
	
	public void addResult(NodeResult newResult) {
		childrenResults.add(newResult);
	}
	
	protected override Map<String,Object> populateMap(Map<String,Object> existingMap) {
		Map<String,Object> mapToPopulate = existingMap;
		if (String.isNotBlank(node.key)) {
			mapToPopulate = new Map<String,Object>();
			existingMap.put(node.key,mapToPopulate);
		}
		//Populate the field values
		populateMapWithChildrenFieldData(mapToPopulate,obj);
		
		//Populate all the children
		for (NodeResult childResult : childrenResults) {
			childResult.populateMap(mapToPopulate);
		}
		
		return existingMap;
	}
	
	public Map<String, Object> buildMap() {
		Map<String, Object> returnMap = new Map<String, Object>();
		return populateMap(returnMap);
	}
	
	/*************** Build object from map ***********************/
	
	public SingleNodeResult(IsolatedSObjectNode nodep,  Map<String, Object> mapping) {
		construct(nodep, nodep.SObjectType,mapping);
	}
	
	public SingleNodeResult(SObject parent, SObjectNode nodep,  Map<String, Object> mapping) {
		String sObjectType = DynamicHelper.getLookupSObjectType(nodep.APIName,parent);
		construct(nodep, sObjectType,mapping);
	}
	
	private void construct(SObjectNode nodep, String sObjectType, Map<String, Object> mapping) {
		node = nodep;
		fieldsIncludedInRequest = new Set<String>();
		childrenResults = new List<NodeResult>();
		obj = DynamicHelper.createObject(sObjectType);
		for (Node childNode : node.nodes) {
			if (childNode.nType == 'Node') {
				if (mapping.keyset().contains(childNode.key)) {
					fieldsIncludedInRequest.add(childNode.APIName);
					obj.put(
						childNode.APIName,
						DynamicHelper.convertValue(
							(String)mapping.get(childNode.key),
							sObjectType,
							childNode.APIName
						)
					);
				}
			} else if (childNode.nType == 'SObjectNode' || childNode.nType == 'IsolatedSObjectNode') {
				Map<String, Object> mapToPopulateWith = mapping;
				if (String.isNotBlank(childNode.key)) {
					mapToPopulateWith = (Map<String, Object>)mapping.get(childNode.key);
				}
				SingleNodeResult newSR = null;
				if (childNode.nType == 'IsolatedSObjectNode') {
					newSR = new SingleNodeResult((IsolatedSObjectNode)childNode, mapToPopulateWith);
				} else {
					newSR = new SingleNodeResult(obj,(SObjectNode)childNode, mapToPopulateWith);
				}

				childrenResults.add(newSr);
				
			} else if (childNode.nType == 'ChildSObjectNode') {
				ChildSObjectNode csn = (ChildSObjectNode)childNode;
				MultiNodeResult newMnr = null;
				if (csn.isCollection) {
					List<Object> childObjectMappings = (List<Object>)mapping.get(csn.key);
					newMnr = new MultiNodeResult(csn,childObjectMappings);
				} else {
					Map<String, Object> mapToPopulateWith = mapping;
					if (String.isNotBlank(csn.key)) {
						mapToPopulateWith = (Map<String, Object>)mapping.get(csn.key);
					}
					newMnr = new MultiNodeResult(csn, new List<Object>{mapToPopulateWith});
				}
				childrenResults.add(newMnr);
			}
		}
	}
	
	public override void deleteRecords(List<SObject> allRecords) {
		for (NodeResult result : childrenResults) {
			result.deleteRecords(allRecords);
		}
		if (obj.id != null) {
			allRecords.add(obj);
		}
	}
	
}