testRunner.service('participants', function (api, $rootScope, $mdDialog, $location) {
    this.broadcastCollectionChanged = function () {
        $rootScope.$broadcast('participants:collectionChanged');
    }

    this.fetch = function (query = {}) {
        return api.action('fetchParticipants', query, false);
    }

  this.save = function(participant) {
    return api.action('saveParticipant', {participant: participant}).then(response => {
      return response.participant;
    });
  }
  
  this.import = function(content) {
    return api.action('importParticipant', {content: content});
  }
  
  this.sendParentEmail = function(participant) {
    return api.action('sendParentEmail', {participant: participant});
  }
  
  this.getDemographicsLink = function(participant) {
    return `${$location.protocol()}://${$location.host()}/test/demographics?pid=${participant.id}&pt=${participant.demographicsToken}`;
  }
  
  this.copyDemographicsLink = function(participant) {
    navigator.clipboard.writeText(this.getDemographicsLink(participant));
  }
});
