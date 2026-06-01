// templates/42
testRunner.component('participantDetailEdit', {
  templateUrl: '/ViewTemplate/EASI-panel-component-participant-detail-edit/html',
  bindings: {
    participant: '=',
    onSave: '&',
    onCancel: '&',
  },
  controller: function controller($scope, auth, transFilter, $mdDialog, constants) {
    $scope.genders = constants.genders;
    $scope.countries = constants.countries;
    $scope.languages = testRunner.R.collections.languages;
    $scope.sensoryIntegrationConcerns = constants.sensoryIntegrationConcerns;
    $scope.assessmentReasons = constants.assessmentReasons;
    $scope.clinicalAssessmentReferrers = constants.clinicalAssessmentReferrers;
    $scope.participant = null;
    $scope.dateOfBirth = null;
    $scope.originalDateOfBirth = null;
    $scope.diagnoses = testRunner.R.collections.diagnoses;
    $scope.researchProjects = testRunner.R.collections.researchProjects;
    $scope.diagnosesSelected = [];
    $scope.researchProjectSelected = [];
    $scope.admin = auth.user;
    $scope.isAdmin = auth.user.type === 1;
    $scope.addingNew = false;
    $scope.suppressDateOfBirthWatch = false;

    this.$onInit = function () {
      $scope.participant = this.participant;
      $scope.addingNew = this.participant.id == undefined;
      $scope.diagnosesSelected = !$scope.addingNew
        ? JSON.parse(this.participant.diagnosesSelected)
        : [];
      $scope.researchProjectSelected = !$scope.addingNew
        ? JSON.parse(this.participant.researchProjectSelected)
        : [];
      $scope.dateOfBirth =
        !$scope.addingNew && this.participant.dateOfBirth
          ? new Date(this.participant.dateOfBirth)
          : null;
      $scope.originalDateOfBirth =
        !$scope.addingNew && this.participant.dateOfBirth
          ? new Date(this.participant.dateOfBirth)
          : null;
    };

    $scope.isMultiCheckSelected = function (selection, item) {
      return selection.indexOf(item) > -1;
    };

    $scope.toggleMultiCheck = function (selection, item) {
      let idx = selection.indexOf(item);
      if (idx > -1) {
        selection.splice(idx, 1);
      } else {
        selection.push(item);
      }
    };

    $scope.$watch('dateOfBirth', function (newValue, oldValue) {
      if (suppressDateOfBirthWatch) {
        suppressDateOfBirthWatch = false;
        return;
      }

      if (newValue === oldValue) return;

      console.log('date of birth changed');
      // if you are not adding new - confirm the birthdate and inform the user that
      // the scores will be recalculated
      let confirmText = addingNew ? 'confirm_birthdate_text' : 'confirm_new_birthdate_warn';
      let confirm = $mdDialog
        .confirm()
        .title(transFilter('confirm_birthdate_title'))
        .textContent(transFilter(confirmText))
        .ok(transFilter('confirm'))
        .cancel(transFilter('cancel'));

      $mdDialog
        .show(confirm)
        .then(function () {
          // User is confirming that the birthdate is correct - dont do anything
          $scope.originalDateOfBirth = newValue;
        })
        .catch((error) => {
          // User is saying that the birthdate is incorrect - put it back to what it was
          suppressDateOfBirthWatch = true;
          !$scope.addingNew ? ($scope.dateOfBirth = $scope.originalDateOfBirth) : null;
        });
    });

    $scope.save = function () {
      let participant = Object.assign($scope.participant, {
        dateOfBirth:
          $scope.dateOfBirth.getFullYear() +
          '-' +
          ($scope.dateOfBirth.getMonth() + 1).toString().padStart(2, '0') +
          '-' +
          $scope.dateOfBirth.getDate().toString().padStart(2, '0'),
        diagnosesSelected: JSON.stringify($scope.diagnosesSelected),
        researchProjectSelected: JSON.stringify($scope.researchProjectSelected),
      });
      $ctrl.onSave({
        participant: participant,
      });
      /*       participants.save(participant).then(participant => {
        $scope.participant.valid = participant.valid;
        notif.toast(transFilter('panel_client_saved', { id: participant.customId }));
      }); */
    };

    $scope.onCancel = function () {
      $ctrl.onCancel();
    };

    $scope.onDobInputKeyPressed = function (event) {
      event.preventDefault();
    };
  },
});
