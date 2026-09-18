function DialogSessionAddController($scope, $mdDialog, tests, sessionAddObject, transFilter) {
  $scope.sessionAddObject = sessionAddObject;
  $scope.testService = tests;
  $scope.selectedSessions = [];
  $scope.testCode = '';
$scope.session = {
  testIteration: null
};
  $scope.hasInitialSession = false;
  $scope.testIteration = null;
  $scope.nextRetestNumber = 0;
  $scope.validEntry = false;
  $scope.cancel = function () {
    $mdDialog.cancel();
  };

$scope.$watch('sessionType', function (value) {
  if (value === 'initial') {
    $scope.session.testIteration = 0;
  }

  if (value === 'retest') {
    $scope.session.testIteration = $scope.nextRetestNumber;
  }

  $scope.validateSession();
});

  $scope.add = function () {
    $scope.session.participant_id = $scope.sessionAddObject.participant_id
      $scope.session.testCode =  $scope.testCode,
      // testIteration: $scope.testIteration,
    
    $mdDialog.hide($scope.session);
  };

  $scope.getSessions = function () {
    $scope.selectedSessions = $scope.sessionAddObject.sessions.filter(
      (x) => x.testCode == $scope.testCode,
    );
    $scope.getNextIteration($scope.selectedSessions);
  };

  $scope.getNextIteration = function (sessions) {
    const iterations = sessions
      .map((session) => session.testIteration)
      .filter((iteration) => iteration != null);

    $scope.hasInitialSession = iterations.includes(0);

    const retestIterations = iterations.filter((iteration) => iteration > 0);

    $scope.nextRetestNumber = retestIterations.length ? Math.max(...retestIterations) + 1 : 1;

    $scope.sessionType = $scope.hasInitialSession ? 'retest' : 'initial';

    $scope.testIteration = $scope.sessionType === 'initial' ? 0 : $scope.nextRetestNumber;
    $scope.validEntry = true;
  };

  $scope.validateSession = function () {
    console.log("testIteration is ", $scope.session.testIteration);
    if (($scope.session.testIteration === undefined) || ($scope.session.testIteration === null)) {
      $scope.validEntry = false;
      return;
    }
    // ensure that the input is not duplicating an existing session
    const idx = $scope.selectedSessions.findIndex((x) => $scope.session.testIteration === x.testIteration);
    $scope.validEntry = idx === -1;
  };
}
