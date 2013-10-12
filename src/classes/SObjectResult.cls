public class SObjectResult {
	public SObject obj							{get; set;}
	public Set<String> fieldsInRequest			{get; set;}
	public Map<String, NodeResult>	childrenMap	{get; set;}
}