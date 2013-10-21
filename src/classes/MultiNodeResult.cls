public class MultiNodeResult extends NodeResult {
	public List<SObjectResult> sObjResults	{get; set;}
	 
	/********** Methods for MultiNodeResult for building from SObjects ********/
	
	public MultiNodeResult(SObjectNode nodep) {
		node = nodep;
		sObjResults = new List<SObjectResult>();
	}

	public List<Object> buildArray() {
		return populateArray();
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
		for (SObjectResult sObjResult : sObjResults) {
			Map<String,Object> objMap = new Map<String,Object>();
			populateMapWithChildrenFieldData(objMap,sObjResult.obj);
			for (NodeResult childResult : sObjResult.childrenMap.values()) {
				childResult.populateMap(objMap);
			}
			returnedArray.add(objMap);
		}
		
		return returnedArray;
	}
	
	private void populateMapWithSingle(Map<String,Object> mapping) {
		if (sObjResults.size() > 0) {
			SObject firstObj = sObjResults[0].obj;
			populateMapWithChildrenFieldData(mapping,firstObj);
			
			for (NodeResult childResult : sObjResults[0].childrenMap.values()) {
				childResult.populateMap(mapping);
			}
			
		}
		
	}
	
	/************************ Methods for building results from map ************/
	
	public MultiNodeResult(IsolatedSObjectNode nodep, List<Object> objects) {
		node = nodep;
		sObjResults = new List<SObjectResult>();
		for (Object obj: objects) {
			SObject newObj = DynamicHelper.createObject(nodep.SObjectType);
			Map<String,Object> mapping = (Map<String,Object>)obj;
			SObjectResult sObjResult = new SObjectResult(node, nodep.SObjectType, mapping);
			sObjResults.add(sObjResult);
		}
	}
	
	public override void deleteRecords(List<SObject> allRecords) {
		List<SObject> mainObjects = new List<SObject>();
		for (SObjectResult objsResult : sObjResults) {
			for (NodeResult result : objsResult.childrenMap.values()) {
				result.deleteRecords(allRecords);
			}
			if (objsResult.obj.id != null) {
				mainObjects.add(objsResult.obj);
			}
		}
		allRecords.addAll(mainObjects);
	}
	
	public void mergeResults(MultiNodeResult otherResult) {
		mergeResults(otherResult,false);
	}
	
	public void mergeResults(MultiNodeResult otherResult, boolean isRoot) {
		IsolatedSObjectNode childNode = (IsolatedSObjectNode)node;

		List<SObjectResultsPair> pairsToMerge = new List<SObjectResultsPair>();
		List<SObject> newObjs = new List<SObject>();

		if ((isRoot || childNode.isCollection) && otherResult.sObjResults.size() > 0) {
			for (SObjectResult newSObjectResult : otherResult.sObjResults) {
				boolean found = false;
				for (SObjectResult sObjectResult : sObjResults) {
					if (sObjectResult.matching(childNode, newSObjectResult)) {
						pairsToMerge.add(new SObjectResultsPair(sObjectResult, newSObjectResult));
						found = true;
					}
				}
				if (!found) {
					sObjResults.add(newSObjectResult);
				}
			}
		} else if (!childNode.isCollection && sObjResults.size() == 1 && otherResult.sObjResults.size() == 1) {
			pairsToMerge.add(new SObjectResultsPair(sObjResults[0], otherResult.sObjResults[0]));
		}
		
		
		for (SObjectResultsPair pair : pairsToMerge) {
			//throw new SingleNodeResult.TestingException(Json.serialize(otherResult.fieldsIncludedForObj) + JSON.serialize(newObj));
			SObjectResult oldResult = pair.origResult;
			SObjectResult newResult = pair.newResult;
			
			newResult.fieldsInRequest.remove('id');
			for (String apiName : newResult.fieldsInRequest) {
				oldResult.obj.put(apiName, newResult.obj.get(apiName));
			}
			
			for (String nodeHash : newResult.childrenMap.keyset()) {
				NodeResult nr = oldResult.childrenMap.get(nodeHash);
				NodeResult otherNr = newResult.childrenMap.get(nodeHash);
				if (nr == null) {
					oldResult.addResult(otherNr);
				} else {
					if (otherNr != null && otherNr instanceof MultiNodeResult) {
						MultiNodeResult mnr = (MultiNodeResult)nr;
						MultiNodeResult otherMnr = (MultiNodeResult)otherNr;
						mnr.mergeResults(otherMnr);
					} else if (otherNr != null && otherNr instanceof SingleNodeResult) {
						SingleNodeResult snr = (SingleNodeResult)nr;
						SingleNodeResult otherSnr = (SingleNodeResult)otherNr;
						snr.mergeResults(otherSnr);
					}
				}
			}
		}
	}
	
	public void addResult(Sobject sObj, NodeResult newResult) {
		for (SObjectResult sObjResult : sObjResults) {
			if (sObj == sObjResult.obj) {
				sObjResult.addResult(newResult);
			}
		}
	}
	
	public List<String> getMatchingFieldValues() {
		IsolatedSObjectNode iNode = (IsolatedSObjectNode)node;
		String apiName = iNode.matchingField;
		if (apiName != null && sObjResults != null && sObjResults.size() > 0) {
			List<String> matchingFieldValues = new List<String>();
			for (SObjectResult sobjRes : sObjResults) {
				if (sobjRes.obj != null) {
					Object val = sobjRes.obj.get(apiName);
					if (val != null) {
						matchingFieldValues.add(String.valueOf(val));
					}
				}
			}
			if (matchingFieldValues.size() > 0) {
				return matchingFieldValues;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	
	private class SObjectResultsPair {
		public SObjectResult origResult	{get; set;}
		public SObjectResult newResult	{get; set;}
		public SObjectResultsPair(SObjectResult origResultp, SObjectResult newResultp) {
			origResult = origResultp;
			newResult = newResultp;
		}
	}
}