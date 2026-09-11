testRunner.controllerProvider.register('assessment', function ($scope, $mdDialog) {
  debugger;
  $scope.items = testRunner.R.items;
  $scope.test = testRunner.R.test;
  $scope.groups = [];
  $scope.discontinueReason = "Item exceeded the child's ability";
  $scope.discontinuing = false;
  $scope.testDiscontinueReason = '';

  $scope.itemSkipReasons = $scope.test.itemSkipReasons
    ? JSON.parse($scope.test.itemSkipReasons)
    : [];

  $scope.testDiscontinueReasons = $scope.test.testDiscontinueReasons
    ? JSON.parse($scope.test.testDiscontinueReasons)
    : [];

  $scope.groupDiscontinueReasons = $scope.test.groupDiscontinueReasons
    ? JSON.parse($scope.test.groupDiscontinueReasons)
    : [];

  $scope.isValid = function (form) {
    if ($scope.items.length === 0) return true;
    if (form && !form.$valid) return false;

    for (let i = 0; i < $scope.items.length; i++) {
      let item = $scope.items[i];
      if (item.required === 1 && item.isValid && !item.isValid()) return false;
    }
    return true;
  };

  $scope.getItemResponses = function () {
    let responses = [];
    for (let i = 0; i < $scope.groups.length; i++) {
      const group = $scope.groups[i];
      for (let x = 0; x < group.stimuli.length; x++) {
        const stimulus = group.stimuli[x];
        for (let y = 0; y < stimulus.items.length; y++) {
          let item = stimulus.items[y];
          let responseValue = null;
          let skipped = false;
          let skipReason = null;
          if ($scope.discontinuing) {
            if (item.value !== undefined || item.skipped) {
              // had existing value leave alone
              responseValue = item.skipped ? null : item.value;
              skipped = item.skipped;
              skipReason = item.skipped ? item.skipReason : null;
            } else {
              responseValue = null;
              skipped = true;
              skipReason = $scope.testDiscontinueReason;
            }
          } else {
            // not discontinuing
            responseValue = item.value;
            if (stimulus.stimulusSkipped !== undefined) {
              skipped = stimulus.stimulusSkipped ? 1 : 0;
            } else {
              skipped = undefined;
            }
            skipReason = stimulus.stimulusSkipped ? stimulus.stimulusSkipReason : null;
          }

          if (responseValue !== undefined || skipped !== undefined) {
            responses.push({
              item_id: item.id,
              value: responseValue,
              skipped: skipped,
              skipReason: skipReason,
            });
          }
        }
      }
    }

    return responses;
  };

  testRunner.addExtraControl('itemResponses', function () {
    return $scope.getItemResponses();
  });

  $scope.skipGroup = function (group) {
    group.groupSkipped = !group.groupSkipped;
    group.groupSkipReason = null;
    group.stimuli.forEach((x) => {
      $scope.skipStimulus(x);
    });
  };

  $scope.skipStimulus = function (stimulus) {
    console.log('lets skip this one: ', stimulus);
    stimulus.stimulusSkipped = !stimulus.stimulusSkipped;
    stimulusSkipReason = null;
    for (let y = 0; y < stimulus.items.length; y++) {
      let item = stimulus.items[y];
      item.skipped = stimulus.stimulusSkipped;
      item.value = null;
      item.skipReason = null;
    }
  };

  $scope.openDiscontinueDialog = function () {
    try {
      const reason = await;
      $mdDialog.show({
        controller: DialogDiscontinueTestController,
        locals: {
          testDiscontinueReasons: $scope.testDiscontinueReasons,
        },

        templateUrl: '/ViewTemplate/EASI-test-discontinue-dialog/html',
        clickOutsideToClose: true,
      });
      console.log('reason was ', reason);
      $scope.testDiscontinueReason = reason;
      $scope.discontinuing = true;
      submitView(true);
    } catch (error) {
      // User clicked Cancel
      console.log('not discontinuing');
    }
  };

  $scope.skipReasonChanged = function (itemType, item) {
    if (itemType === 'stimulus') {
      const stimulus = item;
      for (let y = 0; y < stimulus.items.length; y++) {
        let item = stimulus.items[y];
        item.skipReason = stimulus.stimulusSkipReason;
      }
    }
    if (itemType === 'group') {
      const group = item;
      for (let x = 0; x < group.stimuli.length; x++) {
        let stimulus = group.stimuli[x];
        stimulus.stimulusSkipped = group.groupSkipped;
        stimulus.stimulusSkipReason = group.groupSkipReason;
        for (let y = 0; y < stimulus.items.length; y++) {
          let item = stimulus.items[y];
          item.skipReason = group.groupSkipReason;
        }
      }
    }
  };

  this.$onInit = function () {
    console.log('hi from assessment - items: ', $scope.items);

    $scope.hasGroups = $scope.test.hasGroups;
    $scope.allowIncomplete = $scope.test.allowIncomplete;
    const groups = $scope.items.reduce((acc, curr) => {
      let matchingGroup = acc.find((group) => group.groupId === curr.groupId);

      if (!matchingGroup) {
        matchingGroup = {
          groupId: curr.groupId,
          groupLabel: curr.groupLabel,
          groupCanSkip: true,
          groupSkipped: false,
          groupSkipReason: null,
          stimuli: [],
          hideGroup: curr.hideGroup === 1,
        };

        acc.push(matchingGroup);
      }

      let matchingStimulus = matchingGroup.stimuli.find(
        (stimulus) => stimulus.stimulusId === curr.stimulusId,
      );

      if (!matchingStimulus) {
        matchingStimulus = {
          stimulusId: curr.stimulusId,
          stimulousStemTrans: curr.stem_trans,
          stimulusCanSkip: curr.skippable === 1,
          stimulusSkipped: undefined,
          stimulusSkipReason: null,
          items: [],
        };

        matchingGroup.stimuli.push(matchingStimulus);
      }

      matchingStimulus.items.push(curr);

      return acc;
    }, []);
    groups.sort((a, b) => a.groupOrder - b.groupOrder);

    groups.forEach((group) => {
      group.stimuli.sort((a, b) => a.stimulusId - b.stimulusId);

      group.stimuli.forEach((stimulus) => {
        stimulus.items.sort((a, b) => a.itemOrder - b.itemOrder);
      });
    });
    $scope.groups = [...groups];
    console.log('groups: ', $scope.groups);
  };
});
