testRunner.controllerProvider.register("intro", function($scope) {
  $scope.token = testRunner.getToken();
  $scope.test = testRunner.R.test;
});
