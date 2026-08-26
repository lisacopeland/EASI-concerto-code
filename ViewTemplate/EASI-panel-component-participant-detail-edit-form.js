testRunner.component('participantDetailEditForm', {
  templateUrl: '/ViewTemplate/EASI-panel-component-participant-detail-edit-form/html',
  bindings: {
    participant: '=',
    onSave: '&',
    onCancel: '&',
  },
  controller: function controller($scope, auth, transFilter, $mdDialog, constants) {
    var $ctrl = this;
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
    $scope.hasResearchProject = ((auth.user.researchGroup !== '') && (auth.user.researchGroup !== null))
    $scope.addingNew = false;
    if ($scope.hasResearchProject) {
      $scope.assessmentReasons.push('Research project');
    }
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
          ? $scope.parseDbDate(this.participant.dateOfBirth)
          : null;
      $scope.originalDateOfBirth =
        !$scope.addingNew && this.participant.dateOfBirth
          ? $scope.parseDbDate(this.participant.dateOfBirth)
          : null;
    };
    
    $scope.parseDbDate = function(dateString) {
      if (!dateString) return null;

        var parts = dateString.split("-");
        return new Date(
          parseInt(parts[0], 10),
          parseInt(parts[1], 10) - 1,
          parseInt(parts[2], 10)
        );
      }

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

    $scope.checkDate = function () {
      const formattedDate = $scope.dateOfBirth.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });
      const confirmText = $scope.addingNew
        ? transFilter('confirm_birthdate_new', { date: formattedDate })
        : transFilter('confirm_birthdate_change', { date: formattedDate });
      const confirmWarn = transFilter('birthdate_change_warning'); 
      let textHtml; 
      if (!$scope.addingNew) {
        textHtml = `<p>${confirmText}</p><p><strong>WARNING: </strong>${confirmWarn}</p>`;
      } else {
        textHtml = `<p>${confirmText}</p>`;
      }
      let confirm = $mdDialog
        .confirm()
        .title(transFilter('confirm_birthdate_title'))
        .htmlContent(textHtml)
        .ok(transFilter('confirm'))
        .cancel(transFilter('cancel'));

      $mdDialog
        .show(confirm)
        .then(function () {
          $scope.save();
        })
        .catch((error) => {
          // User is saying that the birthdate is incorrect - put it back to what it was
          $scope.dateOfBirth = $scope.originalDateOfBirth;
        });
    };

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
        valid: true,
      });
      $ctrl.onSave({
        participant: participant,
      });
    };

    $scope.onSave = function () {
      //If the date of birth has changed, confirm
      if ($scope.dateOfBirth !== $scope.originalDateOfBirth) {
        $scope.checkDate();
      } else {
        $scope.save();
      }
    };

    $scope.onCancel = function () {
      $ctrl.onCancel();
    };
  },
});
