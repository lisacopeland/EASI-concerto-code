testRunner.component('msg', {
  templateUrl: "/ViewTemplate/EASI-component-msg/html",
  bindings: {
    type: "@"
  },
  transclude: true,
  controller: function controller($scope) {
    $scope.icon = null;
    $scope.palette = "default";
    
    let getIcon = function(type) {
      switch(type) {
        case "warning": return "warning"
        default: return null;
      }
    }
    
    let getPalette = function(type) {
      switch(type) {
        case "warning": return "warn";
        default: return "default";
      }
    }
    
    this.$onInit = function() {
      $scope.icon = getIcon(this.type);
      $scope.palette = getPalette(this.type);
    }
  }
});
