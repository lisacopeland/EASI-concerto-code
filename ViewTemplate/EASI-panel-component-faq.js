testRunner.component('faq', {
  templateUrl: "/ViewTemplate/EASI-panel-component-faq/html",
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
