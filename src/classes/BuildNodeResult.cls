public class BuildNodeResult {
	
	/***************** Build node results from SObject in Database *************************/
	
	public static MultiNodeResult BuildNodeResultBySFId(IsolatedSObjectNode node, List<String> sfIds) {
		return BuildNodeResult(node, sfIds, 'id');
	}
	
	public static SingleNodeResult BuildNodeResultBySFId(IsolatedSObjectNode node, String sfIds) {
		return BuildNodeResult(node, sfIds, 'id');
	}
	
	public static MultiNodeResult BuildNodeResult(IsolatedSObjectNode node, List<String> identifiers) {
		return BuildNodeResult(node, identifiers, node.matchingField);
	}
	
	public static SingleNodeResult BuildNodeResult(IsolatedSObjectNode node, String identifier) {
		return BuildNodeResult(node, identifier, node.matchingField);
	}
	
	public static MultiNodeResult BuildNodeResult(IsolatedSObjectNode node, List<String> identifiers, String identifierKey) {
		MultiNodeResult nodeResult = new MultiNodeResult(node);
		List<SObject> objs = DynamicHelper.queryAllFields(node.SObjectType, identifierKey, identifiers);
		for (SObject obj : objs) {
			nodeResult.sObjResults.add(new SObjectResult(obj));
		}
		processChildrenMulti(node,new List<MultiNodeResult>{nodeResult});
		return nodeResult;
	}
	
	public static SingleNodeResult BuildNodeResult(IsolatedSObjectNode node, String identifier, String identifierKey) {
		SingleNodeResult nodeResult = new SingleNodeResult(node);
		List<SObject> objs = DynamicHelper.queryAllFields(node.SObjectType, identifierKey, new List<String>{identifier});
		if (objs.size() != 1) {
			return null;
		}
		nodeResult.sObjResult = new SObjectResult(objs[0]);
		Map<SObject, SingleNodeResult> singleMap = new Map<SObject, SingleNodeResult>{
			nodeResult.sObjResult.obj => nodeResult
		};
		processChildrenSingle(node, singleMap);
		return nodeResult;
	}
	
	private static Map<SObject, SingleNodeResult> processesLookup(SObjectNode node, List<SObject> parents) {
		if (parents == null || parents.size() == 0)
			return null;
		String sObjectType = DynamicHelper.getLookupSObjectType(node.APIName, parents[0]);
			
		Map<SObject, SingleNodeResult> resultMap = new Map<SObject, SingleNodeResult>();
		Map<SObject, SingleNodeResult> currentObjMap = new Map<SObject, SingleNodeResult>();
		Map<String, SObject> parentMap = new Map<String, SObject>();
		for (SObject parent: parents) {
			String refId = (String)parent.get(node.APIName);
			if (refId != null) {
				parentMap.put(refId, parent);
			}
		}
		List<SObject> sObjects = DynamicHelper.queryAllFields(sObjectType, 'id', new List<String>(parentMap.keyset()));
		for (SObject obj : sObjects) {
			SingleNodeResult result = new SingleNodeResult(node);
			result.sObjResult = new SObjectResult(obj);
			String objId = (String)obj.id;
			SObject parent = parentMap.get(objId);
			resultMap.put(parent, result);
			currentObjMap.put(obj, result);
		}
		
		processChildrenSingle(node, currentObjMap);
		
		return resultMap;
	}
	
	private static Map<SObject,MultiNodeResult> processesChild(ChildSObjectNode node, List<SObject> parents) {
		if (parents == null || parents.size() == 0)
			return null;

		Map<SObject,MultiNodeResult> nodeResults = new Map<SObject, MultiNodeResult>();
		Map<String, SObject> allParentsMap = new Map<String, SObject>();
		for (SObject parent : parents) {
			String key = (String)parent.get('id');
			allParentsMap.put(key,parent);
		}
		List<SObject> sObjects = DynamicHelper.queryAllFields(node.SObjectType, node.relationKey, new List<String>(allParentsMap.keySet()));
		for (SObject obj: sObjects) {
			String parentsId = (String)obj.get(node.relationKey);
			SObject parent = allParentsMap.get(parentsId);
			MultiNodeResult result = nodeResults.get(parent);
			if (result == null) {
				result = new MultiNodeResult(node);
				nodeResults.put(parent, result);
			}
			result.sObjResults.add(new SObjectResult(obj));
		}
		
		return nodeResults;
	}
	
	private static void processChildrenSingle(SObjectNode node, Map<SObject, SingleNodeResult> previousResults) {
		for (Node childNode : node.nodes) {
			Map<SObject, NodeResult> results = null;
			if (childNode.nType == 'SObjectNode') {
				SObjectNode sNode = (SObjectNode)childNode;
				results = processesLookup((SObjectNode)childNode, new List<SObject>(previousResults.keyset()));
				processChildrenSingle(sNode,(Map<SObject, SingleNodeResult>)results);
			} else if (childNode.nType == 'ChildSObjectNode') {
				ChildSObjectNode cNode = (ChildSObjectNode)childNode;
				results = processesChild((ChildSObjectNode)childNode, new List<SObject>(previousResults.keyset()));
				processChildrenMulti(cNode, (List<MultiNodeResult>)results.values());
			}
			
			if (results != null) {
				for (SObject parent: results.keyset()) {
					SingleNodeResult parentNodeResult = previousResults.get(parent);
					parentNodeResult.addResult(results.get(parent));
				}
			}
		}
	}
	
	private static void processChildrenMulti(SObjectNode node, List<MultiNodeResult> previousResults) {
		//issues with multiple parents maybe? doubtfull though
		Map<SObject,MultiNodeResult> currentSObjToItsResult = new Map<SObject,MultiNodeResult>();
		for (MultiNodeResult result: previousResults) {
			for (SObjectResult objResult : result.sObjResults) {
				currentSObjToItsResult.put(objResult.obj,result);
			}
		}

		for (Node childNode : node.nodes) {
			Map<SObject, NodeResult> results = null;
			if (childNode.nType == 'SObjectNode') {
				SObjectNode sNode = (SObjectNode)childNode;
				results = processesLookup(sNode, new List<SObject>(currentSObjToItsResult.keyset()));
				processChildrenSingle(sNode,(Map<SObject, SingleNodeResult>)results);
			} else if (childNode.nType == 'ChildSObjectNode') {
				ChildSObjectNode cNode = (ChildSObjectNode)childNode;
				results = processesChild(cNode, new List<SObject>(currentSObjToItsResult.keyset()));
				processChildrenMulti(cNode, (List<MultiNodeResult>)results.values());
			}
			
			if (results != null) {
				for (SObject parent: results.keyset()) {
					MultiNodeResult parentNodeResult = currentSObjToItsResult.get(parent);
					parentNodeResult.addResult(parent, results.get(parent));
				}
			}
		}
	}
}