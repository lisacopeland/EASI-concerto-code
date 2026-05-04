testRunner.component('itemSubtract', {
  templateUrl: "/ViewTemplate/EASI-test-component-item-subtract/html",
  bindings: {
    item: '='
  },
  controller: function controller($scope, transFilter) {
    $scope.language = testRunner.R.language;
    $scope.focused = false;
    $scope.settings = {};
    $scope.defaultSkipLabel = transFilter('skip');
    $scope.skipLabel = null;
    $scope.placeholderLeft = null;
    $scope.placeholderRight = null;

    let isValid = function () {
      return $scope.item.value !== undefined && $scope.item.value !== null || $scope.item.skipped;
    }

    let getSkipLabel = function (item) {
      return $scope.settings['skipLabel_' + $scope.language] ? $scope.settings['skipLabel_' + $scope.language] : ($scope.settings.skipLabel ? $scope.settings.skipLabel : $scope.defaultSkipLabel);
    }

    let getPlaceholderLeft = function (item) {
      return $scope.settings['placeholderLeft_' + $scope.language] ? $scope.settings['placeholderLeft_' + $scope.language] : $scope.settings.placeholderLeft;
    }

    let getPlaceholderRight = function (item) {
      return $scope.settings['placeholderRight_' + $scope.language] ? $scope.settings['placeholderRight_' + $scope.language] : $scope.settings.placeholderRight;
    }

    this.$onInit = function () {
      $scope.item = this.item;
      if (this.item.extraSettings) $scope.settings = JSON.parse(this.item.extraSettings);

      try {
        const values = JSON.parse(this.item.value);
        if (values.length !== 2) throw new Error('invalid value');
        $scope.left = parseFloat(values[0]);
        $scope.right = parseFloat(values[1]);
        $scope.item.value = [$scope.left, $scope.right];
        console.log($scope.item.value);
      } catch (ex) {
        this.item.value = undefined;
        $scope.left = undefined;
        $scope.right = undefined;
      }

      $scope.item.isValid = isValid;
      $scope.skipLabel = getSkipLabel($scope.item);
      $scope.placeholderLeft = getPlaceholderLeft($scope.item);
      $scope.placeholderRight = getPlaceholderRight($scope.item);
    }

    $scope.onFocus = function () {
      $scope.focused = true;
    }

    $scope.onBlur = function () {
      $scope.focused = false;
    }

    $scope.subtract = function () {
      if ($scope.left === null || $scope.left === undefined || $scope.right === null || $scope.right === undefined) {
        $scope.item.value = null;
        return;
      }

      $scope.item.value = [$scope.left, $scope.right];
    }

    $scope.onSkipChanged = function () {
      if ($scope.item.skipped) {
        $scope.item.value = null;
        $scope.left = null;
        $scope.right = null;
      }
    }
  }
});
