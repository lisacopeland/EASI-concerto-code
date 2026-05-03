const defaultColors = [
  "#3366CC", "#DC3912", "#FF9900", "#109618", "#990099", "#3B3EAC", "#0099C6", "#DD4477", "#66AA00", "#B82E2E", "#316395", "#994499", "#22AA99", "#AAAA11", "#6633CC", "#E67300", "#8B0707", "#329262", "#5574A6", "#651067"
];

testRunner.filterProvider.register('formatScoreValue', function() {
  return function(scoreValue, scoreName) {
    if(isNaN(scoreValue) || scoreName.indexOf('z score') === -1) return scoreValue;

    const clampedValue = scoreValue = Math.max(-3, Math.min(scoreValue, 3));
    if(clampedValue === 3) return ">" + clampedValue;
    else if(clampedValue === -3) return "<" + clampedValue;

    return clampedValue;
  };
});

testRunner.controllerProvider.register("feedback", function($scope, scores, transFilter) {
  $scope.scores = testRunner.R.scores;
  $scope.participant = testRunner.R.participant;
  $scope.emptyScores = $scope.scores === null || Object.keys($scope.scores).length === 0;
  $scope.test = testRunner.R.test;

  $scope.scoresHistoryCollection = [];
  $scope.metrics = [];
  $scope.dataSets = [];
  $scope.ongoingFetchesNum = 0;
  $scope.query = {
    metrics: {},
    allMetrics: 1,
    datesPreset: 'all'
  };

  $scope.makeFeedback = function() {
    $scope.feedback = [];
    for(let name in $scope.scores) {
      const matchingFeedback = testRunner.R.feedback.find(feedbackElem => {
        const regex = new RegExp(feedbackElem.namePattern);
        return regex.test(name) && (feedbackElem.minRange === undefined || feedbackElem.minRange < $scope.scores[name]) && (feedbackElem.maxRange === undefined || feedbackElem.maxRange >= $scope.scores[name]);
      });
      if(matchingFeedback) {
        $scope.feedback.push({
          name: name,
          value: $scope.scores[name],
          feedback: matchingFeedback.feedback_trans
        });
      }
    }
  }

  let makeDataSet = function() {
    let dataSets = [];
    for(let i=0;i<$scope.metrics.length;i++) {
      let metric = $scope.metrics[i];

      dataSets.push({
        label: transFilter(metric),
        data: $scope.scoresHistoryCollection.filter(score => score.name === metric).map(score => {
          if(score.name.indexOf("z score") !== -1 && !isNaN(score.value)) score.value = Math.max(-3, Math.min(score.value, 3));
          return score;
        }),
        parsing: {
          xAxisKey: 'timeCreated',
          yAxisKey: 'value'
        },
        backgroundColor: defaultColors[i],
        borderColor: defaultColors[i],
        color: defaultColors[i]
      });
    }
    $scope.dataSets = dataSets;
  }

  let chart = null;
  let drawChart = function() {
    if(chart !== null) {
      chart.destroy();
      chart = null;
    }

    const elem = document.getElementById('chart');
    if(elem) {
      const ctx = document.getElementById('chart').getContext('2d');
      chart = new Chart(ctx, {
        type: 'line',
        data: {
          datasets: $scope.dataSets
        },
        options: {
          scales: {
            y: {
              beginAtZero: true
            },
            x: {
              type: 'time',
              time: {
                unit: 'day'
              }
            }
          },
          plugins: {
            legend: {
              labels: {
                font: {
                  size: 16
                }
              }
            }
          }
        }
      });
    }
  }

  $scope.getScores = function() {
    $scope.ongoingFetchesNum++;
    scores.fetch($scope.query).then(response => {
      $scope.scoresHistoryCollection = response.collection;
      $scope.metrics = response.metrics;

      makeDataSet();
      drawChart();
      $scope.ongoingFetchesNum--;
      $scope.$apply();
    });
  }

  $scope.returnToPanel = function() {
    location.href = "/test/panel#!/participant/"+$scope.participant.id+"/sessions";
  }

  if(testRunner.R.test.returnToPanel == 1) {
    $scope.returnToPanel();
  } else {
    $scope.getScores();
    $scope.makeFeedback();
  }
});