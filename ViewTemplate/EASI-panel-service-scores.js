testRunner.service('scores', function(api) {
  this.fetch = function(query = {}) {
    return api.action('fetchScores', query, false);
  }
  
  this.fetchSession = function(query = {}) {
    return api.action('fetchSessionScores', query, false);
  }
});