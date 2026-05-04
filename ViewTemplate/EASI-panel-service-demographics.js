testRunner.service('demographics', function(api) {
  this.fetch = function(participantId) {
    return api.action('fetchDemographics', {participantId: participantId}, false);
  }
});
