testRunner.component('participantAdd', {
  templateUrl: '/ViewTemplate/EASI-panel-component-participant-add/html',
  controller: function controller($scope, $location, participants, notif, auth, transFilter) {
    $scope.participant = {
      customId: null,
      dateOfBirth: null,
      countryOfResidence: null,
      admin_id: auth.user.id,
      gender: '',
      languageCode: '',
      diagnoses: null,
      diagnosesSelected: [],
      valid: false,
      demographicsStatus: 0,
      demographicsToken: null,
      initials: null,
      email: null,
      assessmentReason: '',
      clinicalAssessmentReferrer: '',
      researchProjectSelected: [],
      researchGroup: null,
      lastAssessmentDate: null,
      archived: false,
      exportExclusion: false,
    };
    this.$onInit = function () {

    };

    $scope.onSave = function (participant) {
      let newParticipant = Object.assign(participant);
      participants.create(newParticipant).then((participant) => {
        notif.toast(transFilter('panel_client_saved', { id: participant.customId }));
        $location.path('/participant/' + participant.id + '/sessions');
      });
    };

    $scope.goBack = function () {
      $location.path('/participant');
    };

    $scope.onCancel = function () {
      $location.path('/participant');
    };
  },
});
