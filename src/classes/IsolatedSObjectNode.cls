public virtual class IsolatedSObjectNode extends SObjectNode{
	public String SObjectType {get;set;}
	public Boolean isCollection {get; set;}
	public String relationKey	{get; set;}
	public String matchingField	{get;set;}
	
	public virtual override String getType() {
		return 'IsolatedSObjectNode';
	}
	
	public override boolean equals(SObjectNode otherP) {
		boolean superEqual = super.equals(otherP);
		if (otherp instanceof IsolatedSObjectNode) {
			IsolatedSObjectNode other = (IsolatedSObjectNode)otherP;
			return superEqual &&
					SObjectType == other.SObjectType &&
					isCollection == other.isCollection &&
					relationKey == other.relationKey;
		} else {
			return false;
		}
	}
	
	public override String getHashKey() {
		if (hashKey == null) {
			hashKey = 'nType:' + nullToEmpty(nType) + ':key:' + nullToEmpty(key) + ':APIName:' + nullToEmpty(APIName) +
			':SObjectType:' + nullToEmpty(SObjectType) + ':relationKey:' + nullToEmpty(relationKey) + ':matchingField:' + nullToEmpty(matchingField);
		}
		return hashKey;
	}
}