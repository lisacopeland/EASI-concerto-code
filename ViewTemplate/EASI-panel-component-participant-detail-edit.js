// templates/42
testRunner.component('participantDetailEdit', {
  templateUrl: '/ViewTemplate/EASI-panel-component-participant-detail-edit/html',
  bindings: {
    participant: '=',
  },
  controller: function controller($scope, participants, notif, auth, transFilter) {
    $scope.participant = null;
    $scope.admin = {};

    this.$onInit = function () {
      $scope.participant = this.participant;
      $scope.admin = auth.user;
    };

    $scope.onSave = function () {
      let newParticipant = Object.assign($scope.participant);

      participants.save(newParticipant).then((participant) => {
        notif.toast(transFilter('panel_client_saved', { id: participant.customId }));
      });
    };

    $scope.onCancel = function () {
      $location.path('/participant');
    };
  },
});
