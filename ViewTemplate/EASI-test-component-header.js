testRunner.component('testHeader', {
  templateUrl: "/ViewTemplate/EASI-test-component-header/html",
  bindings: {},
  controller: function controller($scope) {
    $scope.token = testRunner.getToken();
    $scope.test = testRunner.R.test;
    $scope.instructionsAvailable = testRunner.R.instructionsAvailable;
    $scope.language = testRunner.R.language;
    $scope.languages = testRunner.R.languages;

    this.$onInit = function() {
    }

    $scope.goToInstructions = function() {
      testRunner.submitView("instructions");
    }
    
    $scope.onLanguageChanged = function() {
      const url = new URL(location.href);
      url.searchParams.set('l', $scope.language);
      location.href = url.href;
    }
  }
});