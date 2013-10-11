public class SavePackage {
	public List<NodeResult> results;
	public SObjectNode node;
		
	public SavePackage(List<NodeResult> resultsP,SObjectNode nodep) {
		results = resultsP;
		node = nodeP;
	}
		
	public List<NodeResult> getAllChildren() {
		List<NodeResult> allChildren = new List<NodeResult>();
			
		for (NodeResult parentResult : results) {
			if (parentResult instanceof SingleNodeResult) {
				allChildren.addAll(((SingleNodeResult)parentResult).childrenResults);
			} else if (parentResult instanceof MultiNodeResult) {
				MultiNodeResult multiParent = (MultiNodeResult)parentResult;
				for (SObject key: multiParent.childrenMapping.keyset()) {
					allChildren.addAll(multiParent.childrenMapping.get(key));
				}
			}
		}
		return allChildren;
	}
		
	public List<SObject> getAllMainSObjects() {
			
		List<SObject> allMainSObjects = new List<SObject>();
		for (NodeResult result : results) {
			if (result instanceof SingleNodeResult) {
				allMainSObjects.add(((SingleNodeResult)result).obj);
			} else if (result instanceof MultiNodeResult) {
				MultiNodeResult multiParent = (MultiNodeResult)result;
				allMainSObjects.addAll(multiParent.objs);
			}
		}
			
		return allMainSObjects;
	}
		
	public List<SObjectNode> getAllLookupNodes() {
		List<SObjectNode> lookupNodes = new List<SObjectNode>();
		for (Node childNode : node.nodes) {
			if (childNode.nType == 'SObjectNode') {
				lookupNodes.add((SObjectNode)childNode);
			} 
		}
		return lookupNodes;
	}
		
	public List<ChildSObjectNode> getAllChildNodes() {
		List<ChildSObjectNode> childNodes = new List<ChildSObjectNode>();
		for (Node childNode : node.nodes) {
			if (childNode.nType == 'ChildSObjectNode') {
				childNodes.add((ChildSObjectNode)childNode);
			}
		}
		return childNodes;
	}

	public void Save() {
		
		List<SObjectNode> allLookupNodes = getAllLookupNodes();
		List<ChildSObjectNode> allChildrenNodes = getAllChildNodes();
		List<SavePackage> allLookupPackages = new List<SavePackage>();
		List<SavePackage> allChildrenPackages = new List<SavePackage>();
		Map<SObjectNode,List<NodeResult>> nodeMap = new Map<SObjectNode,List<NodeResult>>();
		
		List<NodeResult> allChildren = getAllChildren();
		
		//order of 2...
		for (Integer i = 0; i < allLookupNodes.size() ; i++) {
			SObjectNode lookupNode = allLookupNodes[i];
			boolean found = false;
			for (NodeResult child : allChildren) {
				if (lookupNode.equals(child.node)) {
					found = true;
					List<NodeResult> simalarNodes = nodeMap.get(lookupNode);
					if (simalarNodes == null) {
						simalarNodes = new List<NodeResult>();
						nodeMap.put(lookupNode,simalarNodes);
					}
					simalarNodes.add(child);
				}
			}
		}
		
		for (SObjectNode key : nodeMap.keySet()) {
			List<NodeResult> results = nodeMap.get(key);
			if (results != null && results.size() != 0) {
				allLookupPackages.add( new SavePackage(results,key));
			}
		}
		nodeMap.clear();
		
		//order of 2...
		for (Integer i = 0; i < allChildrenNodes.size() ; i++) {
			ChildSObjectNode childNode = allChildrenNodes[i];
			boolean found = false;
			for (NodeResult child : allChildren) {
				if (childNode.equals(child.node)) {
					found = true;
					List<NodeResult> simalarNodes = nodeMap.get(childNode);
					if (simalarNodes == null) {
						simalarNodes = new List<NodeResult>();
						nodeMap.put(childNode,simalarNodes);
					}
					simalarNodes.add(child);
				}
			}
			if (found) {
				allChildrenNodes.remove(i);
				i--;
			}
		}
		
		for (SObjectNode key : nodeMap.keySet()) {
			List<NodeResult> results = nodeMap.get(key);
			if (results != null && results.size() != 0) {
				allChildrenPackages.add( new SavePackage(results,key));
			}
		}
		
		for (SavePackage lookupPackage: allLookupPackages) {
			lookupPackage.save();
		}
		
		// associate lookup packages to main sobjects
		// @todo clean this shit up
		for (NodeResult result : results) {
			if (result instanceof MultiNodeResult) {
				MultiNodeResult mnr = (MultiNodeResult)result;
				for (Node node : mnr.node.nodes) {
					if (node.nType == 'SObjectNode') {
						SObjectNode sObjNode = (SObjectNode)node;
						for (SObject obj : mnr.objs) {
							List<NodeResult> objsResults = mnr.childrenMapping.get(obj);
							if (objsResults != null) {
								for (NodeResult nodeR : objsResults) {
									if (sObjNode.equals(nodeR.node)) {
										SingleNodeResult snr = (SingleNodeResult)nodeR;
										obj.put(sObjNode.APIName, (ID)snr.obj.get('id'));
									}
								}
							}
						}
					}
				}
			} else if (result instanceof SingleNodeResult) {
				SingleNodeResult parentSnr = (SingleNodeResult)result;
				for (Node node : parentSnr.node.nodes) {
					if (node.nType == 'SObjectNode') {
						SObjectNode sObjNode = (SObjectNode)node;
						for (NodeResult nodeR : parentSnr.childrenResults) {
							if (sObjNode.equals(nodeR.node)) {
								SingleNodeResult snr = (SingleNodeResult)nodeR;
								parentSnr.obj.put(sObjNode.APIName, (ID)snr.obj.get('id'));
							}
						}
					}
				}
			}
		}
		List<SObject> allPackageSObjects = getAllMainSObjects();
		List<SObject> insertList = new List<SObject>();
		List<SObject> updatetList = new List<SObject>();
		for (SObject sObj : allPackageSObjects) {
			if (sObj.id == null) {
				insertList.add(sObj);
			} else {
				updatetList.add(sObj);
			}
		}
		if (insertList.size() > 0) {
			insert insertList;
		}
		
		if (updatetList.size() > 0) {
			update updatetList;
		}
		
		//associate the children with the main objects
		// @todo clean this shit up
		for (NodeResult result : results) {
			if (result instanceof MultiNodeResult) {
				MultiNodeResult mnr = (MultiNodeResult)result;
				for (Node node : mnr.node.nodes) {
					if (node.nType == 'ChildSObjectNode') {
						ChildSObjectNode sObjNode = (ChildSObjectNode)node;
						for (SObject obj : mnr.objs) {
							List<NodeResult> objsResults = mnr.childrenMapping.get(obj);
							if (objsResults != null) {
								for (NodeResult nodeR : objsResults) {
									if (sObjNode.equals(nodeR.node)) {
										MultiNodeResult childResults = (MultiNodeResult)nodeR;
										for (SObject childObj : childResults.objs) {
											childObj.put(sObjNode.relationKey, (Id)obj.get('id'));
										}
									}
								}
							}
						}
					}
				}
			} else if (result instanceof SingleNodeResult) {
				SingleNodeResult parentSnr = (SingleNodeResult)result;
				if (parentSnr.childrenResults != null) {
					for (Node node : parentSnr.node.nodes) {
						if (node.nType == 'ChildSObjectNode') {
							ChildSObjectNode sObjNode = (ChildSObjectNode)node;
							for (NodeResult nodeR : parentSnr.childrenResults) {
								if (sObjNode.equals(nodeR.node)) {
									MultiNodeResult childResults = (MultiNodeResult)nodeR;
									if (childResults.objs != null) {
										for (SObject childObj : childResults.objs) {
											childObj.put(sObjNode.relationKey, (Id)parentSnr.obj.get('id'));
										}
									}
								}
							}
						}
					}
				}
			}
		}
		
		for (SavePackage childPackage: allChildrenPackages) {
			childPackage.save();
		}
	}
}