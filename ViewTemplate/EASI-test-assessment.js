testRunner.controllerProvider.register('assessment', function ($scope) {
  debugger;
  $scope.items = testRunner.R.items;
  $scope.test = testRunner.R.test;
  $scope.groups = [];

  $scope.skipReasons = [
    "Item exceeded the child's ability",
    'Hyperreactivity',
    'Inattention or other behavioral reasons',
    'Ran out of time',
    'Missing materials',
    'Unintentionally skipped',
  ];

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
          responses.push({
            item_id: item.id,
            value: item.value,
            skipped: stimulus.skipped ? 1 : 0,
            skipReason: stimulus.skipped ? stimulus.stimulusSkipReason : null,
          });
        }
      }
    }

    /*     for (let i = 0; i < $scope.items.length; i++) {
      let item = $scope.items[i];
      responses.push({
        item_id: item.id,
        value: item.value,
        skipped: item.skipped ? 1 : 0,
        skipReason: ' ',
      });
    } */
    return responses;
  };

  testRunner.addExtraControl('itemResponses', function () {
    return $scope.getItemResponses();
  });

  $scope.skipThisOne = function (stimulus) {
    console.log('lets skip this one: ', stimulus);
    stimulus.stimulusSkipped = true;
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
    $scope.groups = [...groups];
    console.log('groups: ', $scope.groups);
  };
});
