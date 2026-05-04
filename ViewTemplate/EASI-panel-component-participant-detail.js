testRunner.component('participantDetail', {
  templateUrl: "/ViewTemplate/EASI-panel-component-participant-detail/html",
  bindings: {},
  controller: function controller($scope, participants, $routeParams, $location, $timeout) {
    $scope.participant = null;
    $scope.section = 'edit';

    this.$onInit = function() {
      console.log($routeParams);
      if($routeParams.section) { $scope.section = $routeParams.section; }
      this.fetchParticipant();
    }

    this.fetchParticipant = function() {
      participants.fetchSingle($routeParams.id).then(participant => {
        $scope.participant = participant;
        $scope.$apply();
        
        //if participant not found go back to list of participants
        if($scope.participant === null) $timeout(function(){$scope.goBack()},0);
      });
    }

    $scope.goTo = function(section) {
      $scope.section = section;
    }

    $scope.goBack = function(){
      $location.path("/participant");
    }
  }
});
