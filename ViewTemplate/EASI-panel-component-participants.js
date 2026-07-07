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
    constants,
  ) {
    let syncingVisibleSelections = false;
    let fetchingParticipants = false;

    $scope.genders = constants.genders;
    $scope.countries = constants.countries;
    $scope.languages = testRunner.R.collections.languages;
    $scope.assessmentReasons = constants.assessmentReasons;
    $scope.clinicalAssessmentReferrers = constants.clinicalAssessmentReferrers;
    $scope.diagnoses = testRunner.R.collections.diagnoses;
    $scope.researchProjects = testRunner.R.collections.researchProjects;
    $scope.selection = {
      mode: 'explicit', // or allmatching
      includedIds: {}, // if explicit, only delete these ids
      allMatching: false, // allmatching true means ALL recods except excludeids
      excludedIds: {}, // if allmatching, only exclude these ids
      filters: {}, // filters passed from the $scope.filters
    };
    $scope.filters = {};
    $scope.isOpen = false;
    $scope.activeFilters = [];
    $scope.filterList = [
      { key: 'admin', label: 'panel_client_administrator' },
      // { key: 'archived', label: 'panel_archived_label' },
      { key: 'assessmentReason', label: 'panel_client_assessment_reason' },
      { key: 'clinicalAssessmentReferrer', label: 'panel_client_clinical_assessment_referrer' },
      { key: 'countryOfResidence', label: 'panel_client_country_of_residence' },
      { key: 'customId', label: 'panel_client_custom_id' },
      { key: 'dateOfBirth', label: 'panel_client_date_of_birth' },
      { key: 'diagnosis', label: 'panel_client_diagnosis_label' },
      // { key: 'diagnosesSelected', label: 'panel_client_select_diagnoses' },
      { key: 'email', label: 'panel_client_email' },
      { key: 'exportExclusion', label: 'panel_client_export_exclusion' },
      { key: 'gender', label: 'panel_client_gender' },
      { key: 'id', label: 'id' },
      { key: 'initials', label: 'panel_client_initials' },
      { key: 'lastAssessment', label: 'panel_client_last_assessment' },
      { key: 'primaryLanguage', label: 'panel_client_primary_language' },
      { key: 'researchProjectSelected', label: 'Research project' },
    ];
    $scope.dictionary = testRunner.R.dictionary;
    $scope.participantsCollection = [];
    $scope.participantsTotalCount = 0;
    $scope.selectedParticipants = [];
    $scope.ongoingFetchesNum = 0;
    $scope.query = {
      order: 'id',
      limit: 100,
      archived: 0,
      page: 1,
      // searchString: undefined
    };

    $scope.filterUi = {
      activeFilter: null,
    };

    $scope.archivedOptions = [
      { value: [0], label: transFilter('panel_archived_nonarchived') },
      { value: [0, 1], label: transFilter('panel_archived_all') },
      { value: [1], label: transFilter('panel_archived_archived') },
    ];

    $scope.selectedArchivedValue = $scope.archivedOptions[0];

    $scope.changeArchiveFilter = function (option) {
      if (option !== $scope.selectedArchivedValue) {
        $scope.selectedArchivedValue = option;
        $scope.filters.archived.value = option.value;
      }
    };

    $scope.isToday = function (date) {
      const now = new Date();
      return (
        date.getUTCFullYear() === now.getUTCFullYear() &&
        date.getUTCMonth() === now.getUTCMonth() &&
        date.getUTCDate() === now.getUTCDate()
      );
    };

    $scope.$watch('query.searchString', function (newVal, oldVal) {
      if (newVal === undefined && oldVal === undefined) {
        return;
      }
      $scope.getParticipants();
    });

    $scope.$watch(
      function () {
        return {
          admin: $scope.filters.admin.value,
          archived: $scope.filters.archived.value,
          assessmentReason: $scope.filters.assessmentReason.value,
          clinicalAssessmentReferrer: $scope.filters.clinicalAssessmentReferrer.value,
          countryOfResidence: $scope.filters.countryOfResidence.value,
          customId: $scope.filters.customId.value,
          dateOfBirthOperator: $scope.filters.dateOfBirth.operator,
          dateOfBirthValue1: $scope.filters.dateOfBirth.value1,
          dateOfBirthValue2: $scope.filters.dateOfBirth.value2,
          diagnoses: $scope.filters.diagnoses.value,
          diagnosesSelected: $scope.filters.diagnosesSelected.value,
          email: $scope.filters.email.value,
          exportExclusion: $scope.filters.exportExclusion.value,
          gender: $scope.filters.gender.value,
          id: $scope.filters.id.value,
          initials: $scope.filters.initials.value,
          lastAssessmentOperator: $scope.filters.lastAssessment.operator,
          lastAssessmentValue1: $scope.filters.lastAssessment.value1,
          lastAssessmentValue2: $scope.filters.lastAssessment.value2,
          primaryLanguage: $scope.filters.primaryLanguage.value,
          researchProjectSelected: $scope.filters.researchProjectSelected.value,
        };
      },
      function (newVal, oldVal) {
        $scope.updateEnabledFilters();
        $scope.updateActiveFilters();
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

    $scope.updateEnabledFilters = function () {
      angular.forEach($scope.filters, function (filter, key) {
        if (Array.isArray(filter.value)) {
          if (key === 'diagnosesSelected') {
            filter.enabled = $scope.filters.diagnoses.value.includes('1');
            if (filter.enabled === false) {
              filter.value = [];
            }
          } else filter.enabled = filter.value.length > 0;
        } else if (key === 'dateOfBirth' || key === 'lastAssessment') {
          filter.enabled =
            filter.operator !== 'equal' ||
            !$scope.isToday(filter.value1) ||
            !$scope.isToday(filter.value2);
        } else {
          filter.enabled =
            filter.value !== null && filter.value !== undefined && filter.value !== '';
        }
      });
    };

    $scope.isAdmin = function () {
      return auth.user.type === 1;
    };

    $scope.paginationLabels = {
      of: transFilter('page_of'),
      page: transFilter('page'),
      rowsPerPage: transFilter('page_rows'),
    };

    $scope.toggleFilterDrawer = function () {
      $scope.isOpen = !$scope.isOpen;
      if (!$scope.isOpen) {
        $scope.filterUi = {
          activeFilter: null,
        };
      }
    };

    $scope.hasFilterValue = function (key) {
      if (key === 'diagnosis') {
        return $scope.filters['diagnoses'].enabled === true;
      }
      const filter = $scope.filters[key];
      return filter.enabled === true;
    };

    $scope.hasDiagnoses = function () {
      const diagnosesValue = $scope.filters['diagnoses'].value;
      if (diagnosesValue.length) {
        return diagnosesValue.find((x) => x === '1') !== undefined;
      }
      return false;
    };

    $scope.getFilterLabel = function (key) {
      const item = $scope.filterList.find((x) => x.key === key);
      return item !== undefined ? item.label : '';
    };

    // Used by the list to show the active filters when the filter window is closed
    $scope.updateActiveFilters = function () {
      $scope.activeFilters = [];

      angular.forEach($scope.filters, function (filter, key) {
        if (filter.enabled && key !== 'archived') {
          if (Array.isArray(filter.value)) {
            $scope.activeFilters.push({
              key: key,
              count: filter.value.length,
            });
          } else {
            $scope.activeFilters.push({
              key: key,
              count: 1,
            });
          }
        }
      });
    };

    $scope.initFilters = function () {
      const now = new Date();
      $scope.selectedArchivedValue = $scope.archivedOptions[0];
      $scope.filters = {
        admin: {
          enabled: false,
          value: '',
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
          value1: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())),
          value2: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())),
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
          value1: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())),
          value2: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())),
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
      $scope.updateActiveFilters();
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

    this.$onInit = function () {
      // Letting paginator do the first fetch
      $scope.clearFilters();
      $scope.$on('participants:collectionChanged', (event) => {
        $scope.getParticipants();
      });
    };

    $scope.getParticipants = function () {
      $scope.ongoingFetchesNum++;
      fetchingParticipants = true;
      participants.fetch($scope.query, JSON.stringify($scope.filters)).then((response) => {
        if (response.success === false) {
          console.error('FETCH PARTICIPANTS FAILED');
        }
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

    $scope.onPaginate = function () {
      $scope.getParticipants();
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
  },
});
