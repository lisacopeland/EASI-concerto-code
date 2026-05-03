testRunner.controllerProvider.register("msg", function($scope) {
  $scope.type = testRunner.R.type;
  $scope.text = testRunner.R.text;
});