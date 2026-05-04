function DialogParticipantAddController($scope, $mdDialog) {
  $scope.participant = {
    customId: ''
  }
  
  $scope.cancel = function () {
    $mdDialog.cancel();
  };

  $scope.add = function () {
    $mdDialog.hide($scope.participant);
  };
}
