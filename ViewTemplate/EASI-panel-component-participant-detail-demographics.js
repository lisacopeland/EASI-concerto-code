testRunner.component('participantDetailDemographics', {
  templateUrl: "/ViewTemplate/EASI-panel-component-participant-detail-demographics/html",
  bindings: {
    participant: "="
  },
  controller: function controller($scope, demographics, participants, notif, transFilter) {
    $scope.participant = null;
    $scope.fields = [];
    $scope.demographicsLoaded = false;

    this.$onInit = function() {
      $scope.participant = this.participant;
      demographics.fetch(this.participant.id).then((response) => {
        $scope.fields = response.demographics;
        $scope.demographicsLoaded = true;
        $scope.$apply();
      });
    }

    $scope.email = function() {
      participants.sendParentEmail($scope.participant).then(() => notif.toast(transFilter('panel_demographics_invitation_resent', {email: $scope.participant.email})));
    }
    
    $scope.copyLink = function() {
      participants.copyDemographicsLink($scope.participant);
      notif.toast(transFilter('panel_demographics_link_copied'));
    }
  }
});
