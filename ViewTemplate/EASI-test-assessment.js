testRunner.controllerProvider.register('assessment', function ($scope, $mdDialog) {
  debugger;
  $scope.items = testRunner.R.items;
  $scope.test = testRunner.R.test;
  $scope.groups = [];
  $scope.discontinueReason = "Item exceeded the child's ability";
  $scope.discontinuing = false;

  $scope.skipReasons = $scope.test.skipReasons;

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
              skipReason = $scope.discontinueReason;
            }
          } else {
            // not discontinuing
            responseValue = item.value;
            skipped = stimulus.stimulusSkipped ? 1 : 0;
            skipReason = stimulus.stimulusSkipped ? stimulus.stimulusSkipReason : null;
          }

          responses.push({
            item_id: item.id,
            value: responseValue,
            skipped: skipped,
            skipReason: skipReason,
          });
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
    stimulus.skippedReason = null;
    for (let y = 0; y < stimulus.items.length; y++) {
      let item = stimulus.items[y];
      item.skipped = stimulus.stimulusSkipped;
      item.value = null;
      item.skipReason = null;
    }
  };

  $scope.openDiscontinueDialog = function () {
    $mdDialog
      .show({
        controller: DialogDiscontinueTestController,
        templateUrl: '/ViewTemplate/EASI-test-discontinue-dialog/html',
        parent: angular.element(document.body),
        clickOutsideToClose: true,
      })
      .then(
        function (reason) {
          console.log('reason was ', reason);
          $scope.discontinueReason = reason;
          $scope.discontinuing = true;
          submitView(true);
        },
        function () {
          console.log('not discontinuing');
        },
      );
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
          item.skipReason = stimulus.stimulusSkipReason;
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
          groupCanSkip: true,
          groupSkipped: false,
          groupSkipReason: null,
          stimuli: [],
        };

        acc.push(matchingGroup);
      }

      let matchingStimulus = matchingGroup.stimuli.find(
        (stimulus) => stimulus.stimulusId === curr.stimulusId,
      );

      if (!matchingStimulus) {
        matchingStimulus = {
          stimulusId: curr.stimulusId,
          stimulusOrder: curr.stimulusOrder,
          stimulousStemTrans: curr.stem_trans,
          stimulusCanSkip: curr.skippable === 1,
          stimulusSkipped: false,
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
      group.stimuli.sort((a, b) => a.stimulusOrder - b.stimulusOrder);

      group.stimuli.forEach((stimulus) => {
        stimulus.items.sort((a, b) => a.itemOrder - b.itemOrder);
      });
    });
    $scope.groups = [...groups];
    console.log('groups: ', $scope.groups);
  };
});
