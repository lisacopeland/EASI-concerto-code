testRunner.component('instructionalVideos', {
  templateUrl: "/ViewTemplate/EASI-panel-component-instructional-videos/html",
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
