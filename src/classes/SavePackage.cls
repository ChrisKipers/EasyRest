public class SavePackage {

	public List<NodeResult> results;
	public SObjectNode node;
		
	public SavePackage(List<NodeResult> resultsP,SObjectNode nodep) {
		results = resultsP;
		node = nodeP;
	}
	
	public void Save() {
		//System.debug(json.serialize(results));
		Set<SObjectNode> lookupNodes = new Set<SObjectNode>();
		Set<ChildSObjectNode> childNodes = new Set<ChildSObjectNode>();
		Map<String, List<NodeResult>> allResultsPerNode = new Map<String, List<NodeResult>>();
		List<FieldNode> nodesWithDefaults = new List<FieldNode>();
		
		for (Node childNode : node.nodes) {
			if (childNode.nType == 'SObjectNode') {
				lookupNodes.add((SObjectNode)childNode);
			} else if (childNode.nType == 'ChildSObjectNode') {
				childNodes.add((ChildSObjectNode)childNode);
			} else if (childNode.nType == 'FieldNode' && String.isNotBlank(childNode.APIName) && childNode instanceof FieldNode){
				FieldNode fChildNode = (FieldNode)childNode;
				if (String.isNotBlank(fChildNode.defaultValue)) {
					nodesWithDefaults.add(fChildNode);
				}
			}
		}
		
		for (NodeResult nr : results) {
			if (nr instanceof SingleNodeResult) {
				SingleNodeResult snr = (SingleNodeResult)nr;
				for (String hashKey : snr.sObjResult.childrenMap.keyset()) {
					List<NodeResult> resultsForNode = allResultsPerNode.get(hashKey);
					if (resultsForNode == null) {
						resultsForNode = new List<NodeResult>();
						allResultsPerNode.put(hashKey, resultsForNode);
					}
					NodeResult childResult = snr.sObjResult.childrenMap.get(hashKey);
					if (childResult != null) {
						resultsForNode.add(childResult);
					}
					
				}
			} else if (nr instanceof MultiNodeResult) {
				MultiNodeResult mnr = (MultiNodeResult)nr;
				for (SObjectResult sObjResult : mnr.sObjResults) {
					for (String hashKey : sObjResult.childrenMap.keyset()) {
						List<NodeResult> resultsForNode = allResultsPerNode.get(hashKey);
						if (resultsForNode == null) {
							resultsForNode = new List<NodeResult>();
							allResultsPerNode.put(hashKey, resultsForNode);
						}
						NodeResult childResult = sObjResult.childrenMap.get(hashKey);
						if (childResult != null) {
							resultsForNode.add(childResult);
						}
					}
					
				}
			}
		}
		
		List<NodeResult> allLookups = new List<NodeResult>();
		List<NodeResult> allChildren = new List<NodeResult>();
		
		for (SObjectNode lNode : lookupNodes) {
			List<NodeResult> lookupsForNode = allResultsPerNode.get(lNode.getHashKey());
			if (lookupsForNode != null) {
				SavePackage sp = new SavePackage(lookupsForNode, lNode);
				sp.save();
			}
		}
		
		for (SObjectNode lNode : lookupNodes) {
			for (NodeResult nr : results) {
				if (nr instanceof SingleNodeResult) {
					SingleNodeResult snr = (SingleNodeResult)nr;
					NodeResult lookup = snr.sObjResult.childrenMap.get(lNode.getHashKey());
					if (lookup != null && lookup instanceof SingleNodeResult) {
						SingleNodeResult sLookup = (SingleNodeResult)lookup;
						if (snr.sObjResult.obj.id == null) {
							snr.sObjResult.obj.put(lNode.APIName, sLookup.sObjResult.obj.id);
						}
					}
				} else if (nr instanceof MultiNodeResult) {
					MultiNodeResult mnr = (MultiNodeResult)nr;
					for (SObjectResult sObjResult : mnr.sObjResults) {
						NodeResult lookup = sObjResult.childrenMap.get(lNode.getHashKey());
						if (lookup != null && lookup instanceof SingleNodeResult) {
							SingleNodeResult sLookup = (SingleNodeResult)lookup;
							if (sObjResult.obj.id == null) {
								sObjResult.obj.put(lNode.APIName, sLookup.sObjResult.obj.id);
							}
						}
					}
				}
			}
		}
		
		
		List<SObject> insertObj = new List<SObject>();
		List<SObject> updateObj = new List<SObject>();
		for (NodeResult nr : results) {
			if (nr instanceof SingleNodeResult) {
				SingleNodeResult snr = (SingleNodeResult)nr;
				if (snr.sObjResult.obj.id == null) {
					String sObjectType = snr.sObjResult.obj.getSObjectType().getDescribe().getName();
					for (FieldNode nodeWithDefault : nodesWithDefaults) {
						if (String.isBlank(nodeWithDefault.key) || !snr.sObjResult.fieldsInRequest.contains(nodeWithDefault.APIName)) {
							snr.sObjResult.obj.put(
								nodeWithDefault.APIName, 
								DynamicHelper.convertValue(
									nodeWithDefault.defaultValue,
									sObjectType,
									nodeWithDefault.APIName
								)
							);
						}
					}
					insertObj.add(snr.sObjResult.obj);
				} else {
					updateObj.add(snr.sObjResult.obj);
				}
				
			} else if (nr instanceof MultiNodeResult) {
				MultiNodeResult mnr = (MultiNodeResult)nr;
				for (SObjectResult sObjResult : mnr.sObjResults) {
					if (sObjResult.obj.id == null) {
						String SObjectType = sObjResult.obj.getSObjectType().getDescribe().getName();
						for (FieldNode nodeWithDefault : nodesWithDefaults) {
							if (String.isBlank(nodeWithDefault.key) || !sObjResult.fieldsInRequest.contains(nodeWithDefault.APIName)) {
								sObjResult.obj.put(
									nodeWithDefault.APIName, 
									DynamicHelper.convertValue(
										nodeWithDefault.defaultValue,
										SObjectType,
										nodeWithDefault.APIName
									)
								);
							}
						}
						insertObj.add(sObjResult.obj);
					} else {
						updateObj.add(sObjResult.obj);
					}
				}
				
			}
		}
		
		if (insertObj.size() > 0) {
			insert insertObj;
		}
		
		if (updateObj.size() > 0) {
			update updateObj;
		}
		
		for (ChildSObjectNode cNode : childNodes) {
			for (NodeResult nr : results) {
				if (nr instanceof SingleNodeResult) {
					SingleNodeResult snr = (SingleNodeResult)nr;
					NodeResult child = snr.sObjResult.childrenMap.get(cNode.getHashKey());
					if (child != null && child instanceof MultiNodeResult) {
						MultiNodeResult mChild = (MultiNodeResult)child;
						for (SObjectResult cSObjectResult : mChild.sObjResults) {
							System.debug('Test: ' + JSON.serialize(cSObjectResult));
							if (cSObjectResult.obj.id == null) {
								cSObjectResult.obj.put(cNode.relationKey, snr.sObjResult.obj.id);
							}
						}
					}
				} else if (nr instanceof MultiNodeResult) {
					MultiNodeResult mnr = (MultiNodeResult)nr;
					for (SObjectResult objResult : mnr.sObjResults) {
						NodeResult child = objResult.childrenMap.get(cNode.getHashKey());
						if (child != null && child instanceof MultiNodeResult) {
							MultiNodeResult mChild = (MultiNodeResult)child;
							for (SObjectResult cSObjResult : mChild.sObjResults) {
								if (cSObjResult.obj.id == null) {
									cSObjResult.obj.put(cNode.relationKey, objResult.obj.id);
								}
							}
						}
					}
				}
			}
		}
		
		for (ChildSObjectNode cNode : childNodes) {
			List<NodeResult> childrenForNode = allResultsPerNode.get(cNode.getHashKey());
			if (childrenForNode != null) {
				SavePackage sp = new SavePackage(childrenForNode, cNode);
				sp.save();
			}
		}
	}
}