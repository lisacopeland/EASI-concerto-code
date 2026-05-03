testRunner.component('panel', {
  templateUrl: "/ViewTemplate/EASI-panel-component-panel/html",
  bindings: {
  },
  controller: function controller($scope, auth, api, $mdDialog, $location, participants, notif, $window, transFilter, admin) {
    $scope.api = api;
    $scope.dictionary = testRunner.R.dictionary;
    $scope.languages = testRunner.R.collections.languages.filter((language) => language.enabled == 1);
    $scope.language = testRunner.R.language;

    this.$onInit = function() {
    }

    $scope.logOut = function() {
      let confirm = $mdDialog.confirm()
      .title(transFilter('panel_logout_prompt'))
      .ok(transFilter('panel_logout_confirm'))
      .cancel(transFilter('cancel'));

      $mdDialog.show(confirm).then(function () {
        auth.logOut().then(()=>$scope.$apply());
      });
    }
    
    $scope.about = function() {
      $location.path('/about');
    }
    
    $scope.other = function() {
      $location.path('/other');
    }
    
    $scope.addClient = function() {
      participants.add({}).then(participant => {
        $location.path('/participant/'+participant.id+'/edit');
        notif.toast(transFilter('panel_client_added', {id: participant.customId}));
      });
    }
    
    $scope.viewClients = function() {
      $location.path('/participant');
    }
    
    $scope.goToExternalUrlFromDictionary = function(url) {
      $window.open($scope.dictionary[url], '_blank');
    }
    
    $scope.faq = function() {
      $location.path('/faq');
    }
    
    $scope.scoringInformation = function() {
      $location.path('/scoring-info');
    }
    
    $scope.editProfile = function() {
      $location.path('/admin/edit');
    }
    
    $scope.instructionalVideos = function() {
      $location.path('/instructionalVideos');
    }
    
    $scope.onLanguageChanged = function() {
      admin.setLanguage(this.language).then(() => {
        location.href = '?lang=' + $scope.language;
      });
    }
  }
});