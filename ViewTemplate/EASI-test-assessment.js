testRunner.controllerProvider.register('assessment', function ($scope) {
  $scope.items = testRunner.R.items;
  $scope.test = testRunner.R.test;
  $scope.hasGroups = false;
  $scope.allowIncomplete = false;

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
    for (let i = 0; i < $scope.items.length; i++) {
      let item = $scope.items[i];
      responses.push({
        item_id: item.id,
        value: item.value,
        skipped: item.skipped ? 1 : 0,
      });
    }
    return responses;
  };

  testRunner.addExtraControl('itemResponses', function () {
    return $scope.getItemResponses();
  });
  this.$onInit = function () {
    console.log('hi from assessment - items: ', $scope.items);
    $scope.hasGroups = $scope.test.hasGroups;
    $scope.allowIncomplete = $scope.test.allowIncomplete;
  };

  const groups = items.reduce((acc, curr) => {
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
        items: [],
      };

      matchingGroup.stimuli.push(matchingStimulus);
    }

    matchingStimulus.items.push(curr);

    return acc;
  }, []);
  console.log('groups: ', groups);
});
