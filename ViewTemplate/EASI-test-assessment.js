testRunner.controllerProvider.register("assessment", function($scope) {
  $scope.items = testRunner.R.items;

  $scope.isValid = function(form) {
    if($scope.items.length === 0) return true;
    if(form && !form.$valid) return false;
    
    for(let i=0;i<$scope.items.length;i++) {
      let item = $scope.items[i];
      if(item.required === 1 && item.isValid && !item.isValid()) return false;
    }
    return true;
  }
  
  $scope.getItemResponses = function() {
    let responses = [];
    for(let i=0;i<$scope.items.length;i++) {
      let item = $scope.items[i];
      responses.push({
        item_id: item.id,
        value: item.value,
        skipped: item.skipped ? 1 : 0
      });
    }
    return responses;
  }
  
  testRunner.addExtraControl("itemResponses", function() {
    return $scope.getItemResponses();
  });
});