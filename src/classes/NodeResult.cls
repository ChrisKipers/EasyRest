public abstract class NodeResult {
	public SObjectNode node	{get; set;}

	protected abstract Map<String,Object> populateMap(Map<String,Object> existingMap);
	
	protected void populateMapWithChildrenFieldData(Map<String,Object> mapping, Sobject obj) {
		for (Node fieldNode : node.nodes) {
			if (fieldNode.nType == 'FieldNode') {
				mapping.put(fieldNode.key, String.valueOf(obj.get(fieldNode.APIName)));
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