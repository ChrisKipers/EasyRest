public virtual class Node {
	public String nType		{get; set;}
	public String key		{get; set;}
	public String APIName	{get; set;}
	
	private String hashKey;
	
	public Node() {
		nType = getType();
	}
	
	public virtual String getType() {
		return 'Node';
	}
	
	public String getHashKey() {
		if (hashKey == null) {
			hashKey = Json.serialize(this);
		}
		return hashKey;
	}
}