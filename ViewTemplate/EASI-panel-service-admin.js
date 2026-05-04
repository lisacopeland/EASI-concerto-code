testRunner.service('admin', function(api, $rootScope, $mdDialog) {
  this.fetch = function(query = {}) {
    return api.action('fetchAdmins', query, false);
  }
  
  this.setLanguage = function(languageCode) {
    return api.action('setAdminLanguage', {languageCode: languageCode});
  }
});
