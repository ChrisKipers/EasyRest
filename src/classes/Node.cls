public virtual class Node {
	public String nType		{get; set;}
	public String key		{get; set;}
	public String APIName	{get; set;}
	
	protected String hashKey;
	
	public Node() {
		nType = getType();
	}
	
	public virtual String getType() {
		return 'Node';
	}
	
	public virtual String getHashKey() {
		if (hashKey == null) {
			hashKey = 'nType:' + nullToEmpty(nType) + ':key:' + nullToEmpty(key) + ':APIName:' + nullToEmpty(APIName);
		}
		return hashKey;
	}
	
	protected String nullToEmpty(String value) {
		if (value == null) {
			return '';
		} else {
			return value;
		}
	}
}