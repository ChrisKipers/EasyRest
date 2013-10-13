[
	{
		"SObjectType":"Account",
		"key" :"",
		"isCollection":false,
		"nType":"IsolatedSObjectNode",
		"nodes": [
			{
				"key":"Name",
				"APIName":"Name",
				"nType":"Node"
			},
			{
				"nType":"ChildSObjectNode",
				"SObjectType":"Contact",
				"relationKey":"AccountId",
				"key":"contacts",
				"isCollection":true,
				"nodes": [
					{
						"key":"fName",
						"APIName":"FirstName",
						"nType":"Node"
					},
					{
						"key":"lName",
						"APIName":"LastName",
						"nType":"Node"
					}
				]
			},
			{
				"nType":"SObjectNode",
				"APIName":"Primary_Contact__c",
				"key":"",
				"nodes": [
					{
						"key":"Contact First Name",
						"APIName":"FirstName",
						"nType":"Node"
					},
					{
						"key":"Contact Last Name",
						"APIName":"LastName",
						"nType":"Node"
					}
				]
			}
		]
	}
]