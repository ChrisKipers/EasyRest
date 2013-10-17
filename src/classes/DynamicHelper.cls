public class DynamicHelper {
	public static sObject createObject(String typeName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
        if (targetType == null) {
            // throw an exception
        }
        
        // Instantiate an sObject with the type passed in as an argument
        //  at run time.
        return targetType.newSObject(); 
    }
    
    public static String getLookupSObjectType(String fieldName, SObject parentObject){
    	Schema.SObjectField sf = parentObject.getSObjectType().getDescribe().fields.getMap().get(fieldName);
    	List<Schema.sObjectType> relationships = sf.getDescribe().getReferenceTo();
    	return relationships[0].getDescribe().getName();
    }
    
    public static String getLookupSObjectType(String fieldName, String parentSObjectType) {
    	Schema.SObjectField sf = schema.getGlobalDescribe().get(parentSObjectType).getDescribe().fields.getMap().get(fieldName);
    	List<Schema.sObjectType> relationships = sf.getDescribe().getReferenceTo();
    	return relationships[0].getDescribe().getName();
    }
    
    public static List<Schema.DescribeFieldResult> getAllFields(String sObjectType) {
    	List<Schema.DescribeFieldResult> allFields = new List<Schema.DescribeFieldResult>();
    	Map<String, Schema.SObjectField> fldObjMap = schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();
    	for(Schema.SObjectField s : fldObjMap.values())
		{
		  Schema.DescribeFieldResult desResults = s.getDescribe();
		  allFields.add(desResults);
		}
		
		return allFields;
    }

	public static List<Schema.ChildRelationship> getAllRelatedObjects(String sObjectType) {
		Schema.SObjectType sObjectSchema = schema.getGlobalDescribe().get(sObjectType);
		Schema.DescribeSObjectResult sd = sObjectSchema.getDescribe();
		List<Schema.ChildRelationship> children = sd.getChildRelationships();
		return children;
		
	}
	
	public static List<Schema.SObjectType> getAllSObjectsInOrg() {
		return schema.getGlobalDescribe().values();
	}

    public static List<SObject> queryAllFields(String sObjectType, String idKey, String idValue)
	{
		String whereStatement =' WHERE ' + idKey + ' = \'' + idValue + '\'';
		return queryAllFields(sObjectType, whereStatement);
	}
	
	public static List<SObject> queryAllFields(String sObjectType, String idKey, List<String> idValues)
	{
		for (Integer i = 0; i < idValues.size(); i++) {
			idValues[i] = '\'' + idValues[i] + '\'';
		}
		String valuesSet = '(' + String.join(idValues,',') + ')';
		String whereStatement =' WHERE ' + idKey + ' In ' + valuesSet + '';
		return queryAllFields(sObjectType, whereStatement);
	}
	
	private static List<SObject> queryAllFields(String sObjectType, String whereStatement)
	{
		Map<String, Schema.SObjectField> fldObjMap = schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();
		List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();
		String theQuery = 'SELECT ';
		for(Schema.SObjectField s : fldObjMapValues)
		{
		   String theName = s.getDescribe().getName();
		   //Geolocation fields blow up query, there is no Geolocation display time to check against for some reason,
		   //So I'm checking on the geolocation field names i know exist in the org
		   if (theName != 'Location_Longitude__c' && theName != 'Location_Latitude__c') {
		      theQuery += theName + ',';
		   }
			
		}
		
		// Trim last comma
		theQuery = theQuery.subString(0, theQuery.length() - 1);
		
		// Finalize query string
		theQuery += ' FROM ' + sObjectType ;

		theQuery += whereStatement;
		
		// Make your dynamic call
		List<sObject> results = Database.query(theQuery);
		return results;
	}
	
	public static object convertValue(String value, String sobjectType, String fieldName) {
		DescribeFieldResult fieldResult = schema.getGlobalDescribe().get(sobjectType).getDescribe().fields.getMap().get(fieldName).getDescribe();
		Object convertedValue = null;
		try {
			if (fieldResult.getType() == Schema.DisplayType.Integer) {
				convertedValue = Integer.valueOf(value);
			} else if (fieldResult.getType() == Schema.DisplayType.base64) {
				convertedValue = Blob.valueOf(value);
			} else if (fieldResult.getType() == Schema.DisplayType.Boolean) {
				convertedValue = Boolean.valueOf(value);
			} else if (fieldResult.getType() == Schema.DisplayType.Combobox) {
				convertedValue = value;
			} else if (fieldResult.getType() == Schema.DisplayType.Currency) {
				convertedValue = Decimal.valueOf(value);
			} else if (fieldResult.getType() == Schema.DisplayType.DataCategoryGroupReference) {
				//throw new BaseApplicationController.DataTypeNotSupportedException('Data type DataCategoryGroupReference is not supported for default values.');
			} else if (fieldResult.getType() == Schema.DisplayType.Date) {
				convertedValue = Date.valueOf(value);
			} else if (fieldResult.getType() == Schema.DisplayType.DateTime) {
				convertedValue = DateTime.valueOf(value);
			} else if (fieldResult.getType() == Schema.DisplayType.Double) {
				convertedValue = Double.valueOf(value);
			} else if (fieldResult.getType() == Schema.DisplayType.Email) {
				convertedValue = value;
			} else if (fieldResult.getType() == Schema.DisplayType.EncryptedString) {
				convertedValue = value;
			} else if (fieldResult.getType() == Schema.DisplayType.Id) {
				convertedValue = (Id)value;
			} else if (fieldResult.getType() == Schema.DisplayType.MultiPicklist) {
				convertedValue = value;
			} else if (fieldResult.getType() == Schema.DisplayType.Percent) {
				convertedValue = Decimal.valueOf(value);
			} else if (fieldResult.getType() == Schema.DisplayType.Phone) {
				convertedValue = value;
			} else if (fieldResult.getType() == Schema.DisplayType.Picklist) {
				convertedValue = value;
			} else if (fieldResult.getType() == Schema.DisplayType.Reference) {
				convertedValue = (Id)value;
			} else if (fieldResult.getType() == Schema.DisplayType.String) {
				convertedValue = value;
			} else if (fieldResult.getType() == Schema.DisplayType.TextArea) {
				convertedValue = value;
			} else if (fieldResult.getType() == Schema.DisplayType.Time) {
				//throw new BaseApplicationController.DataTypeNotSupportedException('Data type Time is not supported for default values.');
			} else if (fieldResult.getType() == Schema.DisplayType.URL) {
				convertedValue = value;
			}
		} catch (System.TypeException e) {}
		
		return convertedValue;
	}
}