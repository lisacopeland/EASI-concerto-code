function DialogSessionAddController($scope, $mdDialog, tests, session) {
  $scope.session = session;
  $scope.testService = tests;
  
  $scope.cancel = function () {
    $mdDialog.cancel();
  };

  $scope.add = function () {
    $mdDialog.hide($scope.session);
  };
}