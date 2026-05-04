testRunner.service('sessions', function(api, $rootScope, $mdDialog, $location, auth) {
  this.broadcastCollectionChanged = function() {
    $rootScope.$broadcast('sessions:collectionChanged');
  }

  this.fetch = function(query = {}) {
    return api.action('fetchSessions', query, false);
  }
  
  this.fetchResponses = function(query = {}) {
    return api.action('fetchSessionResponses', query, false);
  }

  this.delete = function(sessions) {
    let ids = {};
    if(!Array.isArray(sessions)) { ids[sessions.testCode] = [sessions.id]; }
    else {
      for(let i=0;i<sessions.length;i++) {
        let session = sessions[i];
        if(!ids[session.testCode]) ids[session.testCode] = [];
        ids[session.testCode].push(sessions[i].id);
      }
    }
    return api.action('deleteSessions', {ids: ids}).then(response => {
      this.broadcastCollectionChanged();
      return response;
    });
  }

  this.addDialog = function(session) {
    let service = this;
    return new Promise((resolve, reject) => {
      $mdDialog.show({
        controller: DialogSessionAddController,
        resolve: {
          session: () => { return session }
        },
        templateUrl: '/ViewTemplate/EASI-panel-dialog-session-add/html',
        parent: angular.element(document.body),
        clickOutsideToClose: true
      }).then(session => {
        resolve(service.add(session));
      });
    });
  }

  this.add = function(session) {
    return api.action('addSession', {
      session: session
    }).then(response => {
      this.broadcastCollectionChanged();
      return response.session;
    });
  }
  
  this.getLink = function(session) {
    return `${$location.protocol()}://${$location.host()}/test/start?tid=${session.testId}&sid=${session.id}&st=${session.token}&aid=${auth.user.id}`;
  }
  
  this.copyLink = function(session) {
    navigator.clipboard.writeText(this.getLink());
  }
  
  this.email = function(session) {
    return api.action('emailSession', {
      session: session
    });
  }
});
