testRunner.component('formOptionsMultiple', {
  templateUrl: "/ViewTemplate/EASI-component-form-optionsMultiple/html",
  bindings: {
    field: '=',
    responses: '=',
    collections: '='
  },
  controller: function controller($scope) {
    $scope.options = [];
    $scope.config = null;
    
    this.$onInit = function() {
      $scope.readonly = this.readonly;
      $scope.field = this.field;
      $scope.responses = this.responses;
      if(!Array.isArray($scope.responses[this.field.name])) $scope.responses[this.field.name] = [];
      if(this.field.config) {
        $scope.config = JSON.parse(this.field.config);
        $scope.options = $scope.config.options;
        if($scope.config.optionsName) $scope.options = this.collections[$scope.config.optionsName];
      }
    }
    
    this.$onDestroy = function() {
      delete this.responses[this.field.name];
    }
    
    $scope.isOptionSelected = function(value) {
      if($scope.responses[$scope.field.name] === undefined) return false;
      return $scope.responses[$scope.field.name].indexOf(value) !== -1;
    }
    
    $scope.toggleOption = function(value) {
      const index = $scope.responses[$scope.field.name].indexOf(value);
      if(index === -1) $scope.responses[$scope.field.name].push(value);
      else $scope.responses[$scope.field.name].splice(index, 1);
    }
  }
});
