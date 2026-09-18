function DialogDiscontinueTestController($scope, $mdDialog, testDiscontinueReasons) {
  $scope.testDiscontinueReasons = testDiscontinueReasons;
  $scope.testDiscontinueReason = '';

  $scope.discontinue = function () {
    $mdDialog.hide($scope.testDiscontinueReason);
  };
  
  $scope.cancel = function () {
    $mdDialog.cancel();
  };
}
