testRunner.service('participants', function (api, $rootScope, $mdDialog, $location) {
  this.broadcastCollectionChanged = function () {
    $rootScope.$broadcast('participants:collectionChanged');
  };

  this.fetch = function (query = {}, filters = '{}') {
    return api.action('fetchParticipants', { ...query, filters: filters }, false);
  };

  this.adminFetch = function (query = {}, admin) {
    return api.action('adminFetchParticipants', { query: query, admin: admin }, false);
  };

  this.fetchSingle = function (id) {
    return api.action('fetchSingleParticipant', { id: id }).then((response) => {
      return response.participant;
    });
  };

  this.delete = function (selection) {
    return api.action('deleteParticipants', { selection: selection }).then((response) => {
      this.broadcastCollectionChanged();
      return response;
    });
  };

  this.toggleArchived = function (participants) {
    let ids = [];
    if (!Array.isArray(participants)) {
      ids.push(participants.id);
    } else {
      for (let i = 0; i < participants.length; i++) {
        ids.push(participants[i].id);
      }
    }
    return api.action('toggleArchivedParticipants', { ids: ids }).then((response) => {
      this.broadcastCollectionChanged();
      return response;
    });
  };

  this.queueExportGeneration = function (participants, cols) {
    let ids = [];
    if (!Array.isArray(participants)) {
      ids.push(participants.id);
    } else {
      for (let i = 0; i < participants.length; i++) {
        ids.push(participants[i].id);
      }
    }
    return api.action('queueExportGeneration', { ids: ids, cols: cols }).then((response) => {
      return response;
    });
  };

  this.checkExportGeneration = function (id) {
    return api.action('checkExportGeneration', { id: id }).then((response) => {
      return response;
    });
  };

  this.add = function (participant) {
    return api.action('addParticipant', { participant: participant }).then((response) => {
      this.broadcastCollectionChanged();
      return response.participant;
    });
  };

  this.save = function (participant) {
    return api.action('saveParticipant', { participant: participant }).then((response) => {
      return response.participant;
    });
  };

  this.import = function (content) {
    return api.action('importParticipant', { content: content });
  };

  this.sendParentEmail = function (participant) {
    return api.action('sendParentEmail', { participant: participant });
  };

  this.getDemographicsLink = function (participant) {
    return `${$location.protocol()}://${$location.host()}/test/demographics?pid=${participant.id}&pt=${participant.demographicsToken}`;
  };

  this.copyDemographicsLink = function (participant) {
    navigator.clipboard.writeText(this.getDemographicsLink(participant));
  };
});
