testRunner.component('participantDetailAudit', {
  templateUrl: "/ViewTemplate/EASI-panel-component-participant-detail-audit/html",
  bindings: {
    participant: "="
  },
  controller: function controller($scope, sessions, scores, $routeParams) {
    $scope.participant = null;
    $scope.sessions = [];

    $scope.selectedSessionFullId = null;
    $scope.session = null;
    $scope.scores = [];
    $scope.responses = [];

    $scope.ongoingFetchesNum = 0;
    $scope.expandables = {
      responses: true,
      scores: true
    };
    $scope.responsesQuery = {
      order: 'item_id'
    };

    this.$onInit = function() {
      $scope.participant = this.participant;
      $scope.refreshSessions().then(() => {
        if($routeParams.action) {
          $scope.selectedSessionFullId = $routeParams.action;
          $scope.refresh();
        }
      });
    }

    let getSession = function(fullId) {
      return $scope.sessions.find(session => session.fullId === fullId);
    }

    $scope.refreshSessions = function() {
      return sessions.fetch({
        order: '-timeFinished',
        participantId: $scope.participant.id,
        testCode: '*'
      }).then(response => $scope.sessions = response.collection.filter(session => session.status === 2));
    }

    $scope.refresh = function() {
      $scope.session = getSession($scope.selectedSessionFullId);
      $scope.refreshAudit();
      $scope.refreshDetails();
    }

    $scope.refreshAudit = function() {
      sessions.fetchResponses({
        testCode: $scope.session.testCode,
        sessionId: $scope.session.id
      }).then(response => {
        $scope.responses = response.collection;
        console.log($scope.responses);
        $scope.$apply();
      });
    }

    $scope.refreshDetails = function() {
      scores.fetchSession({
        testCode: $scope.session.testCode,
        sessionId: $scope.session.id
      }).then(response => {
        $scope.scores = response.collection;
        $scope.$apply();
      });
    }
  }
});