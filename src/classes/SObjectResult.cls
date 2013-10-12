public class SObjectResult {
	public SObject obj							{get; set;}
	public Set<String> fieldsInRequest			{get; set;}
	public Map<String, NodeResult>	childrenMap	{get; set;}
	
	public SObjectResult(SObject objp) {
		obj = objp;
		childrenMap = new Map<String, NodeResult>();
	}
	
	public SObjectResult (SObjectNode node, String sObjectType, Map<String, Object> mapping) {
		fieldsInRequest = new Set<String>();
		childrenMap = new Map<String, NodeResult>();
		obj = DynamicHelper.createObject(sObjectType);
		for (Node childNode : node.nodes) {
			if (childNode.nType == 'FieldNode' && String.isNotBlank(childNode.APIName)) {
				if (String.isNotBlank(childNode.key) && mapping.keyset().contains(childNode.key)) {
					fieldsInRequest.add(childNode.APIName);
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
				if (mapToPopulateWith != null) {
					SingleNodeResult newSR = null;
					if (childNode.nType == 'IsolatedSObjectNode') {
						newSR = new SingleNodeResult((IsolatedSObjectNode)childNode, mapToPopulateWith);
					} else {
						newSR = new SingleNodeResult(obj,(SObjectNode)childNode, mapToPopulateWith);
					} 
	  
					addResult(newSr);
				}
				
			} else if (childNode.nType == 'ChildSObjectNode') {
				ChildSObjectNode csn = (ChildSObjectNode)childNode;
				MultiNodeResult newMnr = null;
				if (csn.isCollection) { 
					List<Object> childObjectMappings = (List<Object>)mapping.get(csn.key);
					if (childObjectMappings != null) {
						newMnr = new MultiNodeResult(csn,childObjectMappings);
						addResult(newMnr);
					}
				} else {
					Map<String, Object> mapToPopulateWith = mapping;
					if (String.isNotBlank(csn.key)) {
						mapToPopulateWith = (Map<String, Object>)mapping.get(csn.key);
					}
					if (mapToPopulateWith != null) {
						newMnr = new MultiNodeResult(csn, new List<Object>{mapToPopulateWith});
						addResult(newMnr);
					}
				}
			}
		}
	}
	
	public void addResult(NodeResult newResult) {
		if (newResult != null) {
			childrenMap.put(newResult.node.getHashKey(), newResult);
		}
	}
	
	public boolean matching(IsolatedSObjectNode node, SObjectResult other) {
		if (String.isNotBlank(node.matchingField)) {
			Object value1 = obj.get(node.matchingField);
			Object value2 = other.obj.get(node.matchingField);
			if (value1 != null && value2 != null) {
				String sValue1 = String.valueOf(value1);
				String sValue2 = String.valueOf(value2);
				if (sValue1 == sValue2) {
					return true;
				}
			}
		}
		
		return false;
	}
}