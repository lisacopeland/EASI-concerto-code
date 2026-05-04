testRunner.component('participantDetailSessions', {
  templateUrl: "/ViewTemplate/EASI-panel-component-participant-detail-sessions/html",
  bindings: {
    participant: "="
  },
  controller: function controller($scope, tests, sessions, $mdSidenav, $mdDialog, notif, $routeParams, $window, $location, $route, transFilter) {
    $scope.participant = null;
    $scope.testService = tests;

    $scope.sessionsCollection = [];
    $scope.sessionsTotalCount = 0;
    $scope.selectedSessions = [];
    $scope.ongoingFetchesNum = 0;
    $scope.query = {
      order: 'testTitle',
      limit: 100,
      search: '',
      page: 1,
      participantId: null,
      testCode: '*'
    };

    this.$onInit = function() {
      $scope.participant = this.participant;
      $scope.query.participantId = this.participant.id;
      tests.fetchAll();
      $scope.getSessions();
      $scope.$on('sessions:collectionChanged', event => $scope.getSessions());
      
      if($location.search().add) {
        $scope.add();
        $location.path('/participant/' + $scope.participant.id + '/sessions').search({});
      }
    }

    let checkIfSelectionValid = function() {
      for(let i=$scope.selectedSessions.length -1;i>=0;i--) {
        if($scope.sessionsCollection.indexOf($scope.selectedSessions[i]) === -1) $scope.selectedSessions.splice(i, 1);
      }
    }

    $scope.getSessions = function() {
      $scope.ongoingFetchesNum++;
      sessions.fetch($scope.query).then(response => {
        $scope.sessionsCollection = response.collection;
        $scope.sessionsTotalCount = response.totalCount;

        checkIfSelectionValid();
        $scope.ongoingFetchesNum--;
        $scope.$apply();
      });
    }

    $scope.add = function() {
      sessions.addDialog({
        participant_id: $scope.participant.id
      }).then(session => {
        notif.toast(transFilter('panel_session_added', {id: $scope.participant.customId}));
      });
    }

    $scope.deleteSelected = function() {
      let num = $scope.selectedSessions.length;
      let confirm = $mdDialog.confirm()
      .title(transFilter('panel_session_remove_prompt', {num: num}))
      .textContent(transFilter('panel_session_remove_content'))
      .ok(transFilter('delete'))
      .cancel(transFilter('cancel'));

      $mdDialog.show(confirm).then(function () {
        sessions.delete($scope.selectedSessions).then(() => {
          notif.toast(transFilter('panel_session_removed', {num: num}));
        });
      });
    }

    $scope.launch = function(session) {
      $window.open(sessions.getLink(session), "_self");
    }

    $scope.copyLaunchLink = function(session) {
      sessions.copyLink(session);
      notif.toast(transFilter('panel_session_launch_link_copied'));
    }

    $scope.email = function(session) {
      sessions.email(session).then(() => notif.toast(transFilter('panel_session_invitation_email_sent')));
    }

    $scope.goToAudit = function(session) {
      const oldPath = $location.path();
      const newPath = '/participant/'+$scope.participant.id+'/audit/'+session.fullId;
      
      if(oldPath !== newPath) {
        $location.path('/participant/'+$scope.participant.id+'/audit/'+session.fullId);
      } else {
        $route.reload();
      }
    }
    
    $scope.paginationLabels = {
      of: transFilter('page_of'), 
      page: transFilter('page'), 
      rowsPerPage: transFilter('page_rows')
    }
  }
});
