testRunner.component('formOptions', {
  templateUrl: "/ViewTemplate/EASI-component-form-options/html",
  bindings: {
    field: '=',
    responses: '=',
    collections: '='
  },
  controller: function controller($scope) {
    $scope.options = [];
    $scope.config = null;
    $scope.subtype = "buttons";
    $scope.layout = "row";
    
    this.$onInit = function() {
      $scope.readonly = this.readonly;
      $scope.field = this.field;
      $scope.responses = this.responses;
      if(this.field.config) {
        $scope.config = JSON.parse(this.field.config);
        $scope.options = $scope.config.options;
        if($scope.config.subtype) $scope.subtype = $scope.config.subtype;
        if($scope.config.layout) $scope.layout = $scope.config.layout;
        if($scope.config.optionsName) $scope.options = this.collections[$scope.config.optionsName];
      }
    }
    
    this.$onDestroy = function() {
      delete this.responses[this.field.name];
    }
    
    $scope.isOptionSelected = function(value) {
      if($scope.responses[$scope.field.name] === undefined) return false;
      return $scope.responses[$scope.field.name] === value;
    }
    
    $scope.selectOption = function(value) {
      $scope.responses[$scope.field.name] = value;
    }
  }
});
