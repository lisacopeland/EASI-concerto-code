testRunner.component('itemOpen', {
  templateUrl: "/ViewTemplate/EASI-test-component-item-open/html",
  bindings: {
    item: '='
  },
  controller: function controller($scope, transFilter) {
    $scope.language = testRunner.R.language;
    $scope.focused = false;
    $scope.settings = {};
    $scope.defaultSkipLabel = transFilter('skip');
    $scope.skipLabel = null;
    $scope.placeholder = null;
    $scope.minValueMessage = null;
    $scope.maxValueMessage = null;
    
    let getSkipLabel = function(item) {
      return $scope.settings['skipLabel_' + $scope.language] ? $scope.settings['skipLabel_' + $scope.language] : ($scope.settings.skipLabel ? $scope.settings.skipLabel : $scope.defaultSkipLabel);
    }
    
    let getPlaceholder = function(item) {
      return $scope.settings['placeholder_' + $scope.language] ? $scope.settings['placeholder_' + $scope.language] : $scope.settings.placeholder;
    }

    let isValid = function() {
      return $scope.item.value !== undefined && $scope.item.value !== null || $scope.item.skipped;
    }

    this.$onInit = function() {
      $scope.item = this.item;
      if(this.item.extraSettings) $scope.settings = JSON.parse(this.item.extraSettings);
      if($scope.settings.inputType == "number") {
        this.item.value = parseFloat(this.item.value);
        if(isNaN(this.item.value)) this.item.value = undefined;
      }

      $scope.item.isValid = isValid;
      $scope.skipLabel = getSkipLabel($scope.item);
      $scope.placeholder = getPlaceholder($scope.item);
    }

    $scope.onFocus = function() {
      $scope.focused = true;
    }

    $scope.onBlur = function() {
      $scope.focused = false;
    }
    
    $scope.onSkipChanged = function() {
      if($scope.item.skipped) {
        $scope.item.value = null;
      }
    }
  }
});