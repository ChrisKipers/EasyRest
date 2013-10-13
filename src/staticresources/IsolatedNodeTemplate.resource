<div class="isolated-node">
	<label>SObject</label>
	<select ng-model="objdata.SObjectType" ng-options="sobject.name as sobject.label for sobject in allSObjects">
	</select>
	<div ng-show="!isRoot">
		<label>Key</label>
		<input type="text" ng-model="objdata.key"/><br/>
		<label>Collection</label>
		<input type="checkbox" ng-model="objdata.isCollection"/>
	</div>
	<div ng-show="matchingFieldOptions.length > 0">
		<label>Matching Field</label>
		<select ng-model="objdata.matchingField" ng-options="o.name as o.label for o in matchingFieldOptions">
		</select>
	</div>
	<div class="field" ng-repeat="node in objdata.nodes">
		<div ng-if="node.nType == 'FieldNode' || node.nType == 'SObjectNode'">
			<field parent="{{objdata.SObjectType}}" fieldchoices="allFieldsForSObjectType" fielddata="node"></field>
		</div>
		<div ng-if="node.nType == 'ChildSObjectNode'">
			<isolatednode objdata="node" parent="{{objdata.SObjectType}}"></isolatednode>
		</div>
	</div>
	<input type="button" value="Add Field" ng-click="addField()" ng-disabled="objdata.SObjectType == ''"/>
	<input type="button" value="Add Related Object"  ng-click="addRelatedObject()" ng-disabled="objdata.SObjectType == ''"/>
</div>