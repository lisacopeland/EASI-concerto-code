testRunner.component('participants', {
  templateUrl: '/ViewTemplate/EASI-panel-component-participants/html',
  bindings: {},
  controller: function controller(
    $scope,
    auth,
    participants,
    admin,
    $timeout,
    $mdSidenav,
    $mdDialog,
    notif,
    $location,
    transFilter,
  ) {
    let syncingVisibleSelections = false;
    let fetchingParticipants = false;

    $scope.languages = testRunner.R.collections.languages;
    $scope.selection = {
      mode: 'explicit', // or allmatching
      includedIds: {}, // if explicit, only delete these ids
      allMatching: false, // allmatching true means ALL recods except excludeids
      excludedIds: {}, // if allmatching, only exclude these ids
      filters: {}, // filters passed from the $scope.filters
    };
    const now = new Date();
    $scope.filters = {};

    $scope.$watch(
      'filters',
      function (newVal, oldVal) {
        $scope.getParticipants();
        participants.filters = $scope.filters;
        $scope.selection.filters = JSON.stringify($scope.filters);
      },
      true,
    );

    $scope.$watchCollection('selectedParticipants', function (newVal, oldVal) {
      if (syncingVisibleSelections || syncingVisibleSelections) {
        return;
      }
      const newIds = {};
      const oldIds = {};

      (newVal || []).forEach((p) => (newIds[p.id] = true));
      (oldVal || []).forEach((p) => (oldIds[p.id] = true));

      Object.keys(newIds).forEach(function (id) {
        if (!oldIds[id]) {
          if ($scope.selection.mode === 'explicit') {
            $scope.selection.includedIds[id] = true;
          } else {
            delete $scope.selection.excludedIds[id];
          }
        }
      });

      Object.keys(oldIds).forEach(function (id) {
        if (!newIds[id]) {
          if ($scope.selection.mode === 'explicit') {
            delete $scope.selection.includedIds[id];
          } else {
            $scope.selection.excludedIds[id] = true;
          }
        }
      });
    });

    $scope.initFilters = function () {
      $scope.filters = {
        admin: {
          enabled: false,
          value: [],
        },
        archived: {
          enabled: true,
          value: [0],
        },
        assessmentReason: {
          enabled: false,
          value: [],
        },
        clinicalAssessmentReferrer: {
          enabled: false,
          value: [],
        },
        countryOfResidence: {
          enabled: false,
          value: [],
        },
        customId: {
          enabled: false,
          value: '',
        },
        dateOfBirth: {
          enabled: false,
          operator: 'equal',
          value1: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getDate())),
          value2: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getDate())),
        },
        diagnoses: {
          enabled: false,
          value: [],
        },
        diagnosesSelected: {
          enabled: false,
          value: [],
        },
        email: {
          enabled: false,
          value: '',
        },
        exportExclusion: {
          enabled: false,
          value: [],
        },
        gender: {
          enabled: false,
          value: [],
        },
        id: {
          enabled: false,
          value: '',
        },
        initials: {
          enabled: false,
          value: '',
        },
        lastAssessment: {
          enabled: false,
          operator: 'equal',
          value1: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getDate())),
          value2: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getDate())),
        },
        primaryLanguage: {
          enabled: false,
          value: [],
        },
        researchProjectSelected: {
          enabled: false,
          value: [],
        },
      };
    };

    $scope.clearFilters = function () {
      $scope.initFilters();
      $scope.$applyAsync();
    };

    $scope.selectAllMatchingParticipants = function () {
      $scope.selection.mode = 'allMatching';
      $scope.selection.includedIds = {};
      $scope.selection.excludedIds = {};
      $scope.selection.filters = JSON.stringify($scope.filters);
      syncVisibleSelections();
    };

    $scope.clearParticipantSelection = function () {
      $scope.selection.mode = 'explicit';
      $scope.selection.includedIds = {};
      $scope.selection.excludedIds = {};
      $scope.selection.filters = JSON.stringify($scope.filters);
      $scope.selectedParticipants = [];
    };

    function syncVisibleSelections() {
      syncingVisibleSelections = true;
      if ($scope.selection.mode === 'allMatching') {
        $scope.selectedParticipants = $scope.participantsCollection.filter(function (participant) {
          return !$scope.selection.excludedIds[participant.id];
        });
      } else {
        $scope.selectedParticipants = $scope.participantsCollection.filter(function (participant) {
          return $scope.selection.includedIds[participant.id];
        });
      }

      $timeout(function () {
        syncingVisibleSelections = false;
      }, 0);
    }

    $scope.dictionary = testRunner.R.dictionary;
    $scope.participantsCollection = [];
    $scope.participantsTotalCount = 0;
    $scope.selectedParticipants = [];
    $scope.ongoingFetchesNum = 0;
    $scope.query = {
      order: 'customId',
      limit: 100,
      archived: 0,
      page: 1,
    };
    $scope.admins = [];

    this.$onInit = function () {
      $scope.clearFilters();
      $scope.getParticipants();
      $scope.$on('participants:collectionChanged', (event) => {
        console.log('participants collection changed! Going to get participants!');
        $scope.getParticipants();
      });
    };

    $scope.getParticipants = function () {
      $scope.ongoingFetchesNum++;
      fetchingParticipants = true;
      participants.fetch($scope.query, JSON.stringify($scope.filters)).then((response) => {
        $scope.participantsCollection = response.collection;
        $scope.participantsTotalCount = response.totalCount;

        syncVisibleSelections();
        $timeout(function () {
          fetchingParticipants = false;
        }, 0);
        $scope.ongoingFetchesNum--;
        $scope.$apply();
      });
    };

    $scope.onReorder = function (order) {
      $scope.query.order = order;
      $scope.query.page = 1;
      $scope.getParticipants();
    };

    $scope.addSingle = function () {
      $location.path('/participant/add');
    };

    $scope.batchImport = function () {
      $location.path('/participant/import');
    };

    function getParticipantSelectionDescription(selection) {
      if (!selection) {
        return 'No participants selected';
      }

      if (selection.mode === 'allMatching') {
        const excludedIds = Object.keys(selection.excludedIds || {});

        if (excludedIds.length === 0) {
          return 'All matching participants';
        }

        return `All matching participants except ids: ${excludedIds.join(', ')}`;
      }

      const includedIds = Object.keys(selection.includedIds || {});

      if (includedIds.length === 0) {
        return 'No participants selected';
      }

      return `Participants with ids: ${includedIds.join(', ')}`;
    }

    function getNumberSelected(selection) {
      if (!selection) {
        return 0;
      }
      if (selection.mode === 'allMatching') {
        const excludedIds = Object.keys(selection.excludedIds || {});

        if (excludedIds.length === 0) {
          return $scope.participantsTotalCount;
        } else {
          return $scope.participantsTotalCount - excludedIds.length;
        }
      }
      const includedIds = Object.keys(selection.includedIds || {});
      return includedIds.length;
    }

    $scope.deleteSelected = function () {
      let num = getNumberSelected($scope.selection);
      let warningMessage = transFilter('panel_client_remove_content');
      let confirm = $mdDialog
        .confirm()
        .title(transFilter('panel_client_remove_prompt', { num: num }))
        .htmlContent(
          `
    <p>${getParticipantSelectionDescription($scope.selection)}</p>
    <p>
      <strong>Warning:</strong>
      ${warningMessage}
    </p>
  `,
        )
        .ok(transFilter('delete_selected'))
        .cancel(transFilter('cancel'));

      $mdDialog.show(confirm).then(function () {
        participants
          .delete($scope.selection)
          .then(() => {
            $scope.clearParticipantSelection();
            notif.toast(transFilter('panel_client_remove_toast', { num: num }));
          })
          .catch((error) => {
            console.error('deleteParticipants failed', error);
            throw error; // optional
          });
      });
    };

    $scope.toggleArchiveSelected = function () {
      let num = getNumberSelected($scope.selection);
      participants.toggleArchived($scope.selection).then(() => {
        notif.toast(transFilter('panel_client_archived_toggled_toast', { num: num }));
      });
    };

    $scope.emailDemographics = function (participant) {
      participants.sendParentEmail(participant).then(() => {
        notif.toast(transFilter('panel_demographics_emailed'));
      });
    };

    $scope.startDemographics = function (participant) {
      const url = participants.getDemographicsLink(participant);
      location.href = url;
    };

    $scope.goToSessions = function (participant) {
      $location.path('/participant/' + participant.id + '/sessions');
    };

    $scope.goToScores = function (participant) {
      $location.path('/participant/' + participant.id + '/scores');
    };

    $scope.edit = function (participant) {
      $location.path('/participant/' + participant.id + '/edit');
    };

    $scope.addSession = function (participant) {
      $location.path('/participant/' + participant.id + '/sessions').search({ add: true });
    };

    $scope.isAdmin = function () {
      return auth.user.type === 1;
    };

    $scope.downloadDialog = function () {
      return new Promise((resolve, reject) => {
        window.scrollTo(0, 0);
        $mdDialog.show({
          controller: DialogParticipantDownloadController,
          resolve: {
            selection: () => {
              return $scope.selection;
            },
          },
          templateUrl: '/ViewTemplate/EASI-panel-dialog-participant-download/html',
          parent: angular.element(document.body),
          clickOutsideToClose: false,
          escapeToClose: false,
        });
      });
    };

    $scope.selectFilters = function () {
      return new Promise((resolve, reject) => {
        window.scrollTo(0, 0);
        $mdDialog.show({
          controller: DialogParticipantFilterController,
          resolve: {
            filters: () => {
              return $scope.filters;
            },
          },
          templateUrl: '/ViewTemplate/EASI-panel-dialog-participant-filter/html',
          parent: angular.element(document.body),
          clickOutsideToClose: true,
          escapeToClose: true,
        });
      });
    };

    $scope.paginationLabels = {
      of: transFilter('page_of'),
      page: transFilter('page'),
      rowsPerPage: transFilter('page_rows'),
    };

    $scope.fetchAdmins = function () {
      console.log(admin);
      admin.fetch().then((response) => {
        $scope.admins = response;
        console.log(response);
      });
    };
  },
});
