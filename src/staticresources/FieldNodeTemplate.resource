<div ng-class="{'field-node' : isField, 'sobject-node' : !isField}">
	<div ng-show="!isRoot">
		<a ng-click="remove()">Remove</a>
	</div>
	<label>Field</label>
	<select ng-model="fielddata.APIName"  ng-options="field.name as field.label for field in fieldchoices">
	</select>
	<br/>
	<label>Key Value</label>
	<input type="text" ng-model="fielddata.key"/>
	<div ng-show="isField">
		<label>Default Value</label>
		<input type="text" ng-model="fielddata.default"/>
	</div>
	<div ng-if="!isField">
		<div ng-repeat="node in fielddata.nodes">
			<div ng-if="node.nType == 'FieldNode' || node.nType == 'SObjectNode'">
				<field parent="{{sObjectType}}" fieldchoices="childFieldChoices" fielddata="node"></field>
			</div>
			<div ng-if="node.nType == 'ChildSObjectNode'">
				<isolatednode objdata="node" parent="{{sObjectType}}"></isolatednode>
			</div>
		</div>
		<input type="button" value="Add Field" ng-click="addField()"/>
		<input type="button" value="Add Related Object" ng-click="addRelatedObject()"/>
	</div>
</div>