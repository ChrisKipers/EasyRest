var app = angular.module('SchemaBuilder',[]);
app.controller('Builder',['$scope',function($scope) {

	$scope.schema = existingSchema
	console.log(existingSchema);

	$scope.saveSchema = function() {
		console.log(angular.toJson($scope.schema));
		submitSchema(angular.toJson($scope.schema));
	}
}]);


app.factory('RecursionHelper', ['$compile', function($compile){
    var RecursionHelper = {
        compile: function(element){
            var contents = element.contents().remove();
            var compiledContents;
            return function(scope, element){
                if(!compiledContents){
                    compiledContents = $compile(contents);
                }
                compiledContents(scope, function(clone){
                    element.append(clone);
                });
            };
        }
    };

    return RecursionHelper;
}]);

app.directive('isolatednode',['RecursionHelper',function(RecursionHelper){
	var directiveDefinitionObject = {
		templateUrl: isolatedNodeTemplateUrl,
		restrict: 'E',
		scope: {
			parent:'@',
			objdata: '=',
			remove: '&'
		},
		controller: ['$scope', '$attrs',function($scope,$attrs){
		//console.log(JSON.stringify($scope.objdata));
			$scope.isRoot = !$scope.parent;
			if (!$scope.objdata.nodes) {
				$scope.objdata.nodes = [];
			}
			
			if (!$scope.sObjectType) {
				$scope.sObjectType = '';
			}
			
			$scope.childObjects = [];
			$scope.allSObjects = [];
			$scope.allFieldsForSObjectType = [];
			$scope.matchingFieldOptions = [];
			$scope.addField = function() {
				$scope.objdata.nodes.push({"nType":"FieldNode"});
			}
			$scope.addRelatedObject = function() {
				$scope.objdata.nodes.push({"nType":"ChildSObjectNode", "isCollection":true});
			}
			
			if ($scope.isRoot) {
				EasyConnect.SchemaBuilderController.getAllSObjectsInOrg(function(result, event){
					$scope.$apply(function(){
						$scope.allSObjects = result;
					});
				});
			} else {
				EasyConnect.SchemaBuilderController.getAllChildren($scope.parent,function(result, event){
					$scope.$apply(function(){
						$scope.allSObjects = result;
					});
				});
			}
			
			$scope.$watch('objdata.SObjectType',function(newValue,oldValue){
				if(newValue || oldValue) {
					if (newValue != oldValue) {
						$scope.objdata.nodes = [];
					}
					if (newValue) {
						EasyConnect.SchemaBuilderController.getFieldsForObject($scope.objdata.SObjectType,function(result, event){
							$scope.$apply(function(){
								$scope.allFieldsForSObjectType = result;
							});
						});
						if (!$scope.isRoot) {
							var newRKey = $scope.getRelationKey($scope.objdata.SObjectType);
							if (newRKey) {
								$scope.objdata.relationKey = newRKey;
							}
						}
					} else {
						$scope.allFieldsForSObjectType = [];
					}
				}
			});
			
			$scope.getRelationKey = function(sObjectType) {
				var relationKey = '';
				$scope.allSObjects.forEach(function(objType){
					if (sObjectType == objType.name) {
						relationKey = objType.relationKey;
						return;
					}
				});
				return relationKey;
			}
			$scope.$watch('objdata.nodes',function(newValue,oldValue){
				$scope.matchingFieldOptions = []
				var found = false;
				$scope.objdata.nodes.forEach(function(node){
					if (node.nType == 'FieldNode' && node.key && node.APIName) {
						$scope.matchingFieldOptions.push({"name": node.APIName, "label" : node.key});
						if ($scope.objdata.matchingField == node.APIName) {
							found = true;
						}
					}
				});
				if (!found) {
					$scope.objdata.matchingField = '';
				}
			},true);
			
			$scope.removeItem = function(index) {
				$scope.objdata.nodes.splice(index,1);
			}
		}],
		compile: function(element) {
			return RecursionHelper.compile(element);
		}
	
	};
	
	return directiveDefinitionObject;
}]);

app.directive('field',['RecursionHelper',function(RecursionHelper){
	var directiveDefinitionObject = {
		templateUrl: fieldNodeTempaleUrl,
		restrict: 'E',
		scope: {
			parent:'@',
			fieldchoices:'=',
			fielddata:'=',
			remove: '&'
		},
		controller: ['$scope', '$attrs',function($scope,$attrs){
				
			$scope.childFieldChoices = [];
			$scope.isField = true;
			if ($scope.fielddata['nType'] == 'SObjectNode') {
				$scope.isField = false;
			}
			$scope.sObjectType = '';
			$scope.getTypeFromAPI = function(apiName) {
				var type = '';
				$scope.fieldchoices.forEach(function(obj){
					if (obj.name == apiName) {
						type = obj.type;
						return;
					}
				});
				return type;
			}
			
			$scope.$watch('fieldchoices', function() {
				$scope.configLookup(false);
			});
		
			$scope.$watch('fielddata.APIName',function() {
				$scope.configLookup(true);
			});
			
			$scope.configLookup = function(clearNodes) {
				var newType = $scope.getTypeFromAPI($scope.fielddata.APIName);
				if (newType) {
					if (newType == 'REFERENCE') {
						$scope.fielddata['nType'] = 'SObjectNode';
						$scope.isField = false;
						if (clearNodes) {
							$scope.fielddata['nodes'] = [];
						}
						EasyConnect.SchemaBuilderController.getFieldsForObjectLookup($scope.fielddata.APIName,$scope.parent,function(result, event){
							$scope.$apply(function(){
								$scope.childFieldChoices = result;
							});
						});
						EasyConnect.SchemaBuilderController.getSObjectType($scope.fielddata.APIName,$scope.parent,function(result, event){
							$scope.$apply(function(){
								$scope.sObjectType = result;
							});
						});
					} else {
						$scope.fielddata['nType'] = 'FieldNode';
						$scope.isField = true;
						delete $scope.fielddata['nodes'];
						$scope.childFieldChoices = [];
						$scope.sObjectType = '';
					}
				}
			}
			
			$scope.addField = function() {
				$scope.fielddata['nodes'].push({'nType':'FieldNode'});
			}
			$scope.addRelatedObject = function() {
				$scope.fielddata['nodes'].push({'nType':'ChildSObjectNode', "isCollection":true});
			}
		}],
		compile: function(element) {
			return RecursionHelper.compile(element);
		}
	
	};
	
	return directiveDefinitionObject;
}]);
