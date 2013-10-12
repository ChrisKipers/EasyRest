public class SavePackage {
	public List<NodeResult> results;
	public SObjectNode node;
		
	public SavePackage(List<NodeResult> resultsP,SObjectNode nodep) {
		results = resultsP;
		node = nodeP;
	}
	
	public void Save() {
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
				for (String hashKey : snr.children.keyset()) {
					List<NodeResult> resultsForNode = allResultsPerNode.get(hashKey);
					if (resultsForNode == null) {
						resultsForNode = new List<NodeResult>();
						allResultsPerNode.put(hashKey, resultsForNode);
					}
					resultsForNode.add(snr.children.get(hashKey));
				}
			} else if (nr instanceof MultiNodeResult) {
				MultiNodeResult mnr = (MultiNodeResult)nr;
				for (SObject obj : mnr.objs) {
					Map<String, NodeResult> objsNodeResults = mnr.childrenMap.get(obj);
					if (objsNodeResults != null) {
						for (String hashKey : objsNodeResults.keyset()) {
							List<NodeResult> resultsForNode = allResultsPerNode.get(hashKey);
							if (resultsForNode == null) {
								resultsForNode = new List<NodeResult>();
								allResultsPerNode.put(hashKey, resultsForNode);
							}
							resultsForNode.add(objsNodeResults.get(hashKey));
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
					NodeResult lookup = snr.children.get(lNode.getHashKey());
					if (lookup != null && lookup instanceof SingleNodeResult) {
						SingleNodeResult sLookup = (SingleNodeResult)lookup;
						snr.obj.put(lNode.APIName, sLookup.obj.id);
					}
				} else if (nr instanceof MultiNodeResult) {
					MultiNodeResult mnr = (MultiNodeResult)nr;
					for (SObject obj : mnr.objs) {
						Map<String, NodeResult> objChildren = mnr.childrenMap.get(obj);
						if (objChildren != null) {
							NodeResult lookup = objChildren.get(lNode.getHashKey());
							if (lookup != null && lookup instanceof SingleNodeResult) {
								SingleNodeResult sLookup = (SingleNodeResult)lookup;
								obj.put(lNode.APIName, sLookup.obj.id);
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
				if (snr.obj.id == null) {
					for (FieldNode nodeWithDefault : nodesWithDefaults) {
						if (String.isBlank(nodeWithDefault.key) || !snr.fieldsIncludedInRequest.contains(nodeWithDefault.key)) {
							snr.obj.put(
								nodeWithDefault.APIName, 
								DynamicHelper.convertValue(
									nodeWithDefault.defaultValue,
									snr.obj.getSObjectType().getDescribe().getName(),
									nodeWithDefault.APIName
								)
							);
						}
					}
					insertObj.add(snr.obj);
				} else {
					updateObj.add(snr.obj);
				}
				
			} else if (nr instanceof MultiNodeResult) {
				MultiNodeResult mnr = (MultiNodeResult)nr;
				for (SObject obj : mnr.objs) {
					if (obj.id == null) {
						Set<String> fieldsIncludedInRequest = mnr.fieldsIncludedForObj.get(obj);
						for (FieldNode nodeWithDefault : nodesWithDefaults) {
							if (String.isBlank(nodeWithDefault.key) || !fieldsIncludedInRequest.contains(nodeWithDefault.key)) {
								obj.put(
									nodeWithDefault.APIName, 
									DynamicHelper.convertValue(
										nodeWithDefault.defaultValue,
										obj.getSObjectType().getDescribe().getName(),
										nodeWithDefault.APIName
									)
								);
							}
						}
						insertObj.add(obj);
					} else {
						updateObj.add(obj);
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
					NodeResult child = snr.children.get(cNode.getHashKey());
					if (child != null && child instanceof MultiNodeResult) {
						MultiNodeResult mChild = (MultiNodeResult)child;
						for (SObject cObj : mChild.objs) {
							cObj.put(cNode.relationKey, snr.obj.id);
						}
					}
				} else if (nr instanceof MultiNodeResult) {
					MultiNodeResult mnr = (MultiNodeResult)nr;
					for (SObject obj : mnr.objs) {
						Map<String, NodeResult> objChildren = mnr.childrenMap.get(obj);
						if (objChildren != null) {
							NodeResult child = objChildren.get(cNode.getHashKey());
							if (child != null && child instanceof MultiNodeResult) {
								MultiNodeResult mChild = (MultiNodeResult)child;
								for (SObject cObj : mChild.objs) {
									cObj.put(cNode.relationKey, obj.id);
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