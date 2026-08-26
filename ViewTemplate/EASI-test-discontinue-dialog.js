function DialogDiscontinueTestController($scope, $mdDialog) {
  $scope.skipReasons = [
    "Item exceeded the child's ability",
    'Hyperreactivity',
    'Inattention or other behavioral reasons',
    'Ran out of time',
    'Missing materials',
    'Unintentionally skipped',
  ];
  $scope.skipReason = '';

  $scope.discontinue = function () {
    $mdDialog.hide($scope.skipReason);
  };
  
  $scope.cancel = function () {
    $mdDialog.cancel();
  };
}
