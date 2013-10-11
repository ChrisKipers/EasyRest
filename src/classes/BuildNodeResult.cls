public class BuildNodeResult {
	
	/***************** Build node results from SObject in Database *************************/
	
	public static MultiNodeResult BuildNodeResult(IsolatedSObjectNode node, List<String> identifiers) {
		MultiNodeResult nodeResult = new MultiNodeResult(node);
		nodeResult.objs = DynamicHelper.queryAllFields(node.SObjectType, node.matchingField, identifiers);
		processChildrenMulti(node,new List<MultiNodeResult>{nodeResult});
		return nodeResult;
	}
	
	public static SingleNodeResult BuildNodeResult(IsolatedSObjectNode node, String identifier) {
		SingleNodeResult nodeResult = new SingleNodeResult(node);
		List<SObject> objs = DynamicHelper.queryAllFields(node.SObjectType, node.matchingField, new List<String>{identifier});
		if (objs.size() != 1) {
			//@todo throw exception
		}
		nodeResult.obj = objs[0];
		Map<SObject, SingleNodeResult> singleMap = new Map<SObject, SingleNodeResult>{
			nodeResult.obj => nodeResult
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
			result.obj = obj;
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
			result.addObject(obj);
		}
		
		return nodeResults;
	}
	
	private static void processChildrenSingle(SObjectNode node, Map<SObject, SingleNodeResult> previousResults) {
		for (Node childNode : node.nodes) {
			Map<SObject, NodeResult> results = null;
			if (childNode.nType == 'SObjectNode') {
				results = processesLookup((SObjectNode)childNode, new List<SObject>(previousResults.keyset()));
			} else if (childNode.nType == 'ChildSObjectNode') {
				results = processesChild((ChildSObjectNode)childNode, new List<SObject>(previousResults.keyset()));
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
			for (SObject obj : result.objs) {
				currentSObjToItsResult.put(obj,result);
			}
		}
		
		for (Node childNode : node.nodes) {
			Map<SObject, NodeResult> results = null;
			if (childNode.nType == 'SObjectNode') {
				results = processesLookup((SObjectNode)childNode, new List<SObject>(currentSObjToItsResult.keyset()));
			} else if (childNode.nType == 'ChildSObjectNode') {
				results = processesChild((ChildSObjectNode)childNode, new List<SObject>(currentSObjToItsResult.keyset()));
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