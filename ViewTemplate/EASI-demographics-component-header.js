testRunner.component('demographicsHeader', {
  templateUrl: "/ViewTemplate/EASI-demographics-component-header/html",
  bindings: {},
  controller: function controller($scope) {
    $scope.token = testRunner.getToken();
    $scope.language = testRunner.R.language;
    $scope.languages = testRunner.R.languages;
    
    this.$onInit = function() {
    }
    
    $scope.onLanguageChanged = function() {
      const url = new URL(location.href);
      url.searchParams.set('l', $scope.language);
      location.href = url.href;
    }
  }
});