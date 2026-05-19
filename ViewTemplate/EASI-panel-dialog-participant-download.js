function DialogParticipantDownloadController(
  $scope,
  $mdDialog,
  $timeout,
  participants,
  selection,
  tests,
) {
  $scope.generationStarted = false;
  $scope.selection = selection;
  $scope.errorMessage = '';
  $scope.status = 0; // not started = 0, in progress = 1, success = 2, error = -1
  $scope.filename = null;
  $scope.cols = {
    assessmentReason: true,
    clinicalAssessmentReferrer: true,
    countryOfResidence: true,
    customId: true,
    dateOfBirth: true,
    diagnoses: true,
    diagnosesSelected: true,
    email: true,
    gender: true,
    id: true,
    initials: true,
    languageCode: true,
    researchGroup: true,
    researchProjectSelected: true,
    testAdmin: true,
    testScores: true,
    testResponses: true,
  };
  $scope.colRequirementsAny = [
    'assessmentReason',
    'clinicalAssessmentReferrer',
    'countryOfResidence',
    'customId',
    'dateOfBirth',
    'diagnoses',
    'diagnosesSelected',
    'email',
    'gender',
    'id',
    'initials',
    'languageCode',
    'researchGroup',
    'researchProjectSelected',
  ];
  $scope.tests = [];

  $scope.download = function () {
    const a = document.createElement('a');
    a.href = `/files/session/${$scope.filename}?token=${testRunner.getToken()}`;
    console.log(a.href);
    a.target = '_blank';
    a.download = $scope.filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    $mdDialog.cancel();
  };

  $scope.cancel = function () {
    $mdDialog.cancel();
  };

  $scope.startGeneration = function () {
    $scope.generationStarted = true;
    $scope.status = 1; // in progress

    participants
      .queueExportGeneration($scope.selection, $scope.cols)
      .then((response) => {
        // this looks like
        //     success = TRUE | false,
        //     filename = filename,
        //     url = filePath
        //     error = "error string"
        if (!response || !response.success) {
          $scope.status = -1;
          $scope.errorMessage = response.error ? response.error : 'error message';
          $scope.$applyAsync();
          return;
        }

        $scope.status = 2;
        $scope.$applyAsync();
        $scope.filename = response.filename;
      })
      .catch((err) => {
        console.error(err);
        $scope.status = -1;
        $scope.$applyAsync();
      });
  };

  $scope.isAnyColumnSelected = function () {
    for (const elem of $scope.colRequirementsAny) {
      if ($scope.cols[elem]) return true;
    }
    return false;
  };

  let initializeTests = function (tests) {
    $scope.tests = tests;
    tests.forEach((test) => ($scope.cols[test.code] = true));
    $scope.$apply();
  };

  tests.fetchAll().then((response) => initializeTests(response.tests));
}
