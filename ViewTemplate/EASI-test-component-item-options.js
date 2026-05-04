testRunner.component('itemOptions', {
  templateUrl: "/ViewTemplate/EASI-test-component-item-options/html",
  bindings: {
    item: '='
  },
  controller: function controller($scope, transFilter) {
    $scope.language = testRunner.R.language;
    $scope.dictionary = testRunner.R.dictionary;
    $scope.options = [];
    $scope.focused = false;
    $scope.settings = {};
    $scope.defaultSkipLabel = $scope.dictionary.skip;
    $scope.skipLabel = null;

    let getSkipLabel = function(item) {
      return $scope.settings['skipLabel_' + $scope.language] ? $scope.settings['skipLabel_' + $scope.language] : ($scope.settings.skipLabel ? $scope.settings.skipLabel : $scope.defaultSkipLabel);
    }

    let setOptions = function(item) {
      for(let i=1;i<=5;i++) {
        let label = item['optionLabel' + i + '_trans'];
        let value = item['optionValue' + i];
        if(label) {
          $scope.options.push({
            label: label,
            value: value
          });
        }
      }
    }

    let isValid = function() {
      return $scope.item.value !== undefined && $scope.item.value !== null || $scope.item.skipped;
    }

    let isKeyboardSelectionIndexBased = function() {
      return $scope.settings.indexBasedKeyboardSelection === true;
    }

    this.$onInit = function() {
      $scope.item = this.item;
      if(this.item.extraSettings) $scope.settings = JSON.parse(this.item.extraSettings);
      setOptions(this.item);

      $scope.item.isValid = isValid;
      $scope.skipLabel = getSkipLabel($scope.item);
    }

    let isValidOption = function(value) { 
      for(let i=0;i<$scope.options.length;i++) {
        if($scope.options[i].value == value) return true;
      }
      return false;
    }

    $scope.selectOption = function(value, $event = null) {   
      if($event) {
        let elem = angular.element($event.currentTarget);
        if(!$scope.focused) elem.parent().parent().focus();
      }

      if(isValidOption(value)) {
        $scope.item.skipped = false;
        $scope.item.value = value;

        //auto focus next
        const tabable = $("[tabindex=0]");
        if(tabable.length > 0) {
          const activeElement = $(document.activeElement);
          const activeIndex = tabable.index(activeElement);
          const nextIndex = (activeIndex + 1) % tabable.length;
          tabable.get(nextIndex).focus();
        }
      }
    }

    $scope.selectSkip = function() {
      $scope.item.skipped = true; 
      $scope.item.value = null;
    }

    $scope.onKeyPressed = function($event) {

      if(isKeyboardSelectionIndexBased()) {
        let maxKeyCode = 48 + $scope.options.length;
        if($event.keyCode >= 49 && $event.keyCode <= maxKeyCode) {
          const selection = $event.keyCode - 49;
          $scope.selectOption($scope.options[selection].value);
        }
      } else {
        const selection = $event.key;
        $scope.selectOption(selection);
      }
    }

    $scope.onFocus = function() {
      $scope.focused = true;
    }

    $scope.onBlur = function() {
      $scope.focused = false;
    }
  }
});
