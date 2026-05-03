testRunner.component('scoringInfo', {
  templateUrl: "/ViewTemplate/EASI-panel-component-scoring-info/html",
  bindings: {
  },
  controller: function controller($scope, $location) {
    $scope.content = testRunner.R.content;
    
    this.$onInit = function() {
    }
    
    $scope.goBack = function() {
      $location.path('/participants');
    }
  }
});