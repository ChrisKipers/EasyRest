public class MultiNodeResult extends NodeResult {
	public List<SObject> objs	{get; set;}
	public Map<SObject, Set<String>> fieldsIncludedForObj	{get; set;}
	 
	public Map<SObject,Map<String, NodeResult>> childrenMap {get; set;}
	 
	/********** Methods for MultiNodeResult for building from SObjects ********/
	
	public MultiNodeResult(SObjectNode nodep) {
		node = nodep;
		childrenMap = new Map<SObject,Map<String, NodeResult>>();
		objs = new List<SObject>();
		fieldsIncludedForObj = new Map<SObject, Set<String>>();
	}

	public List<Object> buildArray() {
		return populateArray();
	}
	
	
	public void addObject(SObject obj) {
		objs.add(obj);
	}
	
	public void addResult(SObject objP, NodeResult result) {
		Map<String, NodeResult> children = childrenMap.get(objP);
		if (children == null) {
			children = new Map<String, NodeResult>();
			childrenMap.put(objP,children);
		}
		children.put(result.node.getHashKey(),result);
	}
	
	protected override Map<String,Object> populateMap(Map<String,Object> existingMap) {
		if (((IsolatedSObjectNode)node).isCollection) {
			List<Object> collection = populateArray();
			existingMap.put(node.key, collection);
		} else {
			Map<String,Object> mapToPopulate = existingMap;
			if (String.isNotBlank(node.key)) {
				mapToPopulate = new Map<String,Object>();
				existingMap.put(node.key,mapToPopulate);
			}
			populateMapWithSingle(mapToPopulate);
		}
		return existingMap;
	}
	
	private List<Object> populateArray() {
		List<Object> returnedArray = new List<Object>();
		for (SObject obj : objs) {
			Map<String,Object> objMap = new Map<String,Object>();
			populateMapWithChildrenFieldData(objMap,obj);
			Map<String, NodeResult> childrenResults = childrenMap.get(obj);
			if (childrenResults != null) {
				for (NodeResult childResult : childrenResults.values()) {
					childResult.populateMap(objMap);
				}
			}
			returnedArray.add(objMap);
		}
		
		return returnedArray;
	}
	
	private void populateMapWithSingle(Map<String,Object> mapping) {
		if (objs != null && objs.size() > 0) {
			SObject firstObj = objs[0];
			populateMapWithChildrenFieldData(mapping,firstObj);
			Map<String, NodeResult> childrenResults = childrenMap.get(firstObj);
			if (childrenResults != null) {
				for (NodeResult childResult : childrenResults.values()) {
					childResult.populateMap(mapping);
				}
			}
		}
		
	}
	
	/************************ Methods for building results from map ************/
	
	public MultiNodeResult(IsolatedSObjectNode nodep, List<Object> objects) {
		node = nodep;
		objs = new List<SObject>();
		childrenMap = new Map<SObject,Map<String, NodeResult>>();
		fieldsIncludedForObj = new Map<SObject, Set<String>>();
		
		for (Object obj: objects) {
			SObject newObj = DynamicHelper.createObject(nodep.SObjectType);
			Set<String> fieldsIncludedInRequest = new Set<String>();
			fieldsIncludedForObj.put(newObj,fieldsIncludedInRequest);
			Map<String,Object> mapping = (Map<String,Object>)obj;
			for (Node childNode : node.nodes) {
				if (childNode.nType == 'Node') {
					if (mapping.keyset().contains(childNode.key)) {
						fieldsIncludedInRequest.add(childNode.APIName);
						newObj.put(
							childNode.APIName,
							DynamicHelper.convertValue(
								(String)mapping.get(childNode.key),
								nodep.SObjectType,
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
						newSR = new SingleNodeResult(newObj,(SObjectNode)childNode, mapToPopulateWith);
					}
					addResult(newObj,newSR);
					
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
					addResult(newObj,newMnr);
				}
			}
			objs.add(newObj);
		}
	}
	
	public override void deleteRecords(List<SObject> allRecords) {
		for (Map<String, NodeResult> results : childrenMap.values()) {
			for (NodeResult result : results.values()) {
				result.deleteRecords(allRecords);
			}
		}
		for (SObject obj : objs) {
			if (obj.id != null) {
				allRecords.add(obj);
			}
		}
	}
}