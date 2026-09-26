testRunner.component('itemOptions', {
  templateUrl: '/ViewTemplate/EASI-test-component-item-options/html',
  bindings: {
    item: '=',
  },
  controller: function controller($scope, transFilter) {
    $scope.language = testRunner.R.language;
    $scope.dictionary = testRunner.R.dictionary;
    $scope.options = [];
    $scope.focused = false;
    $scope.settings = {};
    $scope.sections = [];

    let isValid = function () {
      return ($scope.item.value !== undefined && $scope.item.value !== null) || $scope.item.skipped;
    };

    this.$onInit = function () {
      $scope.item = this.item;
      if (this.item.extraSettings) $scope.settings = JSON.parse(this.item.extraSettings);
      $scope.setOptions();

      $scope.item.isValid = isValid;
    };

    $scope.setOptions = function () {
      $scope.options = extraSettings.options.map(function (option) {
        return {
          value: option.value,
          label: option.label,
          criteria: option.criteria.map(function (criterion) {
            return {
              label: criterion,
              selected: $scope.item.value.includes(criterion),
            };
          }),
        };
      });
    };

    $scope.updateValue = function () {
      $scope.item.value = [];

      $scope.options.forEach(function (option) {
        option.criteria.forEach(function (criterion) {
          if (criterion.selected) {
            $scope.item.value.push(criterion.label);
          }
        });
      });
    };

    $scope.onFocus = function () {
      $scope.focused = true;
    };

    $scope.onBlur = function () {
      $scope.focused = false;
    };
  },
});
