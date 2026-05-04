testRunner.service('admin', function(api, $rootScope, $mdDialog) {
  this.setLanguage = function(languageCode) {
    return api.action('setAdminLanguage', {languageCode: languageCode});
  }
});
