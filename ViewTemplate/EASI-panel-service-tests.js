testRunner.service('tests', function(api) {
  this.collection = [];

  this.fetchAll = function() {
    return api.action('fetchAllTests', {}, false).then(response => {
      this.collection = response.tests;
      return response;
    });
  }
});
