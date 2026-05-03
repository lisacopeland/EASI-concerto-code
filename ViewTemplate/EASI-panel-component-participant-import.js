testRunner.directive('ngFile',function(){
  return {
    restrict: 'A',
    scope: {
      ngModel: '=',
      ngChange: '&',
      type: '@'
    },
    link: function (scope, element, attrs) {
      if(scope.type && scope.type.toLowerCase()!='file'){
        return;
      }
      element.bind('change', function(){
        let files =  element[0].files;
        scope.ngModel = files;
        scope.$apply();
        scope.ngChange();
      });
    }
  }
});

testRunner.component('participantImport', {
  templateUrl: "/ViewTemplate/EASI-panel-component-participant-import/html",
  bindings: {},
  controller: function controller($scope, $location, participants, notif, transFilter) {

    $scope.messages = [];
    $scope.fileHeight = 1;
    $scope.vals = {};

    this.$onInit = function() {
    }

    $scope.goBack = function(){
      $location.path("/participants");
    }
    
    let onImportFinished = function(response) {
      $scope.messages = response.messages;
      angular.element("input[type='file']").val(null);
      $scope.$apply();
      
      if($scope.messages.length === 0) {
        notif.toast(transFilter('panel_client_imported', {num: response.num}));
      } else {
        notif.toast(transFilter('panel_client_import_failed'));
      }
    }

    $scope.fileChanged = function() {
      $scope.messages = [];
      if($scope.vals.file.length > 0) {
        var reader = new FileReader();
        reader.onload = function(evt) {
          participants.import(evt.target.result).then(response => onImportFinished(response));
        };
        reader.readAsText($scope.vals.file[0]);
      }
    }
  }
});