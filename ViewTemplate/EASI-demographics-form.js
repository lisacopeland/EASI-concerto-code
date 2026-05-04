testRunner.controllerProvider.register("form", function($scope) {
  $scope.fields = testRunner.R.fields;
  $scope.responses = {};
  $scope.collections = testRunner.R.collections;
  
  $scope.canShow = function(field) {
    if(!field.showCondition) return true;
    
    const values = $scope.responses;
    return eval(field.showCondition);
  }
  
  testRunner.addExtraControl("responses", () => $scope.responses);
});
