function DialogParticipantFilterController($scope, $mdDialog, filters) {
  $scope.filters = filters;

  $scope.onChange = function(filterName) {
    if($scope.filters[filterName].enabled) return;
    
    switch(filterName) {
      case 'admin':
      case 'assessmentReason':
      case 'archived':
      case 'clinicalAssessmentReferrer':
      case 'countryOfResidence':
      case 'diagnoses':
      case 'diagnosesSelected':
      case 'exportExclusion':
      case 'gender':
      case 'primaryLanguage':
      case 'researchProjectSelected':
        $scope.filters[filterName] = {
          enabled: false,
          value: []
        };
        break;
      case 'dateOfBirth':
      case 'lastAssessment':
        const now = new Date();
        $scope.filters[filterName] = {
          enabled: false,
          operator: 'equal',
          value1: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getDate())),
          value2: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getDate()))
        };
        break;
      case 'customId':
      case 'email':
      case 'id':
      case 'initials':
        $scope.filters[filterName] = {
          enabled: false,
          value: ''
        };
        break;
    }
  }

  $scope.ok = function () {
    $mdDialog.hide();
  };
}
