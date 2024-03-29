public class NodeTreeConstructor {
	public static List<IsolatedSObjectNode> constructNodeTree(String schemaBody) {

		Map<String,Object> root = (Map<String,Object>)JSON.deserializeUntyped(schemaBody);
		
		List<IsolatedSObjectNode> rootsObjects = new List<IsolatedSObjectNode>();
		rootsObjects.add(buildIsolatedSObject(root));

		
		return rootsObjects;
	}
	
	private static IsolatedSObjectNode buildIsolatedSObject(Map<String,Object> nodeMap) {
		IsolatedSObjectNode node = new IsolatedSObjectNode();
		node.key = (String)nodeMap.get('key');
		node.SObjectType = (String)nodeMap.get('SObjectType');
		node.isCollection = (Boolean)nodeMap.get('isCollection');
		List<Object> nodes = (List<Object>)nodeMap.get('nodes');
		node.relationKey = (String)nodeMap.get('relationKey');
		node.matchingField = (String)nodeMap.get('matchingField');
		node.nodes = constructNodeList(nodes);
		return node;
	}
	
	private static Node buildFieldNode(Map<String,Object> nodeMap) {
		FieldNode fieldNode = new FieldNode();
		fieldNode.key = (String)nodeMap.get('key');
		fieldNode.APIName = (String)nodeMap.get('APIName');
		fieldNode.defaultValue = (String)nodeMap.get('default');
		return fieldNode;
	}
	
	private static SObjectNode buildLookupNode(Map<String,Object> nodeMap){
		SObjectNode objNode = new SObjectNode();
		objNode.APIName = (String)nodeMap.get('APIName');
		objNode.key = (String)nodeMap.get('key');
		objNode.nodes = constructNodeList((List<Object>)nodeMap.get('nodes'));
		return objNode;
	}
	
	private static ChildSObjectNode buildChildNode(Map<String,Object> nodeMap){
		ChildSObjectNode objNode = new ChildSObjectNode();
		objNode.SObjectType = (String)nodeMap.get('SObjectType');
		objNode.key = (String)nodeMap.get('key');
		objNode.relationKey = (String)nodeMap.get('relationKey');
		objNode.isCollection = (Boolean)nodeMap.get('isCollection');
		objNode.nodes = constructNodeList((List<Object>)nodeMap.get('nodes'));
		objNode.matchingField = (String)nodeMap.get('matchingField');
		return objNode;
	}
	
	private static List<Node> constructNodeList(List<Object> nodes) {
		List<Node> returnNodes = new List<Node>();
		for (Object childNodeMapObj: nodes) {
			Map<String,Object> childNodeMap = (Map<String,Object>)childNodeMapObj;
			String nType = (String)childNodeMap.get('nType');
			Node childNode = null;
			if (nType == 'SObjectNode') {
				childNode = buildLookupNode(childNodeMap);
			} else if (nType == 'ChildSObjectNode') {
				childNode = buildChildNode(childNodeMap);
			} else if (nType == 'FieldNode') {
				childNode = buildFieldNode(childNodeMap);
			}
			if (childNode != null) {
				returnNodes.add(childNode);
			}
		}
		return returnNodes;
	}
}