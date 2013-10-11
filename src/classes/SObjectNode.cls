public virtual class SObjectNode extends Node{
	public List<Node> nodes	{get;set;}
	
	public void addNode(Node n) {
		nodes.add(n);
	}
	
	public virtual override String getType() {
		return 'SObjectNode';
	}
	
	public virtual boolean equals(SObjectNode other) {
		return (other.nType == nType &&
				other.APIName == APIName &&
				other.key == key);
	}
}