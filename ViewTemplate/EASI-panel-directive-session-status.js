testRunner.directive("sessionStatus", function($compile){
  return{
    restrict: 'A',
    scope: {
      sessionStatus: '<'
    },
    link: function(scope, element, attributes){
      scope.$watch('sessionStatus', function(newValue) {
        let html = 'unknown';
        switch(newValue) {
          case 0: //not started
            html = "<span><md-icon style='color: red;'>not_interested</md-icon></span>";
            break;
          case 1: //ongoing
            html = "<span><md-icon style='color: orange;'>hourglass_empty</md-icon></span>";
            break;
          case 2: //completed
            html = "<span><md-icon style='color: green;'>done</md-icon></span>";
            break;
        }
        $compile(html)(scope, function(result, scope){ 
          element.html(result); 
        });
      });
    }
  }
});