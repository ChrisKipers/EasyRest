public class SingleNodeResult extends NodeResult {
	public SObjectResult sObjResult	{get; set;}
	
	/******************** Methods used to construct node from SObject ***************/
	public SingleNodeResult(SObjectNode nodep) {
		node = nodep;
	}
	
	public void addResult(NodeResult newResult) {
		sObjResult.addResult(newResult);
	}
	 
	protected override Map<String,Object> populateMap(Map<String,Object> existingMap) {
		Map<String,Object> mapToPopulate = existingMap;
		if (String.isNotBlank(node.key)) {
			mapToPopulate = new Map<String,Object>();
			existingMap.put(node.key,mapToPopulate);
		}
		//Populate the field values
		populateMapWithChildrenFieldData(mapToPopulate,sObjResult.obj);
		
		//Populate all the children
		for (NodeResult childResult : sObjResult.childrenMap.values()) {
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
		sObjResult = new SObjectResult(nodeP, sObjectType, mapping);
	}
	
	public override void deleteRecords(List<SObject> allRecords) {
		for (NodeResult result : sObjResult.childrenMap.values()) {
			result.deleteRecords(allRecords);
		}
		if (sObjResult.obj.id != null) {
			allRecords.add(sObjResult.obj);
		}
	}
	
	public void mergeResults(SingleNodeResult otherResult) {
		otherResult.sObjResult.fieldsInRequest.remove('id');
		for (String apiName : otherResult.sObjResult.fieldsInRequest) {
			sObjResult.obj.put(apiName, otherResult.sObjResult.obj.get(apiName));
		}
		
		for (String nodeHash : otherResult.sObjResult.childrenMap.keyset()) {
			NodeResult nr = sObjResult.childrenMap.get(nodeHash);
			NodeResult otherNr = otherResult.sObjResult.childrenMap.get(nodeHash);
			if (nr == null) {
				sObjResult.addResult(otherNr);
			} else {
				if (otherNr != null && otherNr instanceof SingleNodeResult) {
					SingleNodeResult snr = (SingleNodeResult)nr;
					SingleNodeResult otherSnr = (SingleNodeResult)otherNr;
					snr.mergeResults(otherSnr);
				} else if (otherNr != null && otherNr instanceof MultiNodeResult) {
					MultiNodeResult mnr = (MultiNodeResult)nr;
					MultiNodeResult otherMnr = (MultiNodeResult)otherNr;
					mnr.mergeResults(otherMnr);
				}
			}
		}
	}
	
	public String getMatchingFieldValue() {
		IsolatedSObjectNode iNode = (IsolatedSObjectNode)node;
		String apiName = iNode.matchingField;
		System.debug('apiName: ' + apiName);
		if (String.isNotBlank(apiName) && sObjResult != null && sObjResult.obj != null) {
			Object value = sObjResult.obj.get(apiName);
			if (value != null) {
				return String.valueOf(value);
			}
		}
		return null;
	}
	
}