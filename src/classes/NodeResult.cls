public abstract class NodeResult {
	public SObjectNode node	{get; set;}

	protected abstract Map<String,Object> populateMap(Map<String,Object> existingMap);
	
	protected void populateMapWithChildrenFieldData(Map<String,Object> mapping, Sobject obj) {
		for (Node childNode : node.nodes) {
			if (childNode.nType == 'FieldNode') {
				FieldNode fieldNode = (FieldNode)childNode;
				if (String.isBlank(fieldNode.APIName) && String.isNotBlank(fieldNode.defaultValue)&& String.isNotBlank(fieldNode.key)) {
					mapping.put(fieldNode.key, fieldNode.defaultValue);
				} else if (String.isNotBlank(fieldNode.key) && String.isNotBlank(fieldNode.APIName)){
					mapping.put(fieldNode.key, String.valueOf(obj.get(fieldNode.APIName)));
				}
				
			}
		}
	}
	/**************** Static class methods ********************************/
	
	public static SingleNodeResult buildResults(IsolatedSObjectNode nodeTree, String identifier) {
		return BuildNodeResult.BuildNodeResult(nodeTree, identifier);
	}
	
	public static MultiNodeResult buildResults(IsolatedSObjectNode nodeTree, List<String> identifiers) {
		return BuildNodeResult.BuildNodeResult(nodeTree, identifiers);
	}

	public void save() {
		SavePackage sp = new SavePackage(new List<NodeResult>{this},node);
		sp.save(); 
	}
	
	public abstract void deleteRecords(List<SObject> allRecords);
	
	public void deleteRecords() {
		List<SObject> allRecords = new List<SObject>();
		deleteRecords(allRecords);
		delete allRecords; 
	} 
}