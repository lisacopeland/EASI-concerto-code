function DialogParticipantDownloadController($scope, $mdDialog, $timeout, participants, selectedParticipants, tests) {
  $scope.generationStarted = false;
  $scope.status = 0;
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
    testResponses: true
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
    'researchProjectSelected'
  ];
  $scope.tests = [];

  $scope.download = function() {
    const a = document.createElement('a');
    a.href = `/files/session/${$scope.filename}?token=${testRunner.getToken()}`;
    console.log(a.href);
    a.target = "_blank";
    a.download = $scope.filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

    $mdDialog.cancel();
  }

  $scope.cancel = function() {
    $mdDialog.cancel();
  }

  $scope.checkExportGeneration = function(exportGenerationId) {
    const ctrl = this;
    $timeout(() => {
      participants.checkExportGeneration(exportGenerationId).then(response => {
        $scope.status = response.status;
        $scope.filename = response.filename;
        $scope.$apply();

        if($scope.status === 0 || $scope.status === 1) {
          ctrl.checkExportGeneration(exportGenerationId);
        } else {
          console.log('status is ', $scope.status);
        }
      });
    }, 10000);
  }

  $scope.startGeneration = function() {
    $scope.generationStarted = true;
    
    participants.queueExportGeneration(selectedParticipants, $scope.cols).then(response => {
      $scope.status = response.status;
      const exportGenerationId = response.id;
      $scope.$apply();

      $scope.checkExportGeneration(exportGenerationId);
    }); 
  }
  
  $scope.isAnyColumnSelected = function() {
   	for(const elem of $scope.colRequirementsAny) {
      if($scope.cols[elem]) return true;
    }
    return false;
  }
  
  let initializeTests = function(tests) {
    $scope.tests = tests;
    tests.forEach(test => $scope.cols[test.code] = true);
    $scope.$apply();
  }
  
  tests.fetchAll().then(response => initializeTests(response.tests));
}