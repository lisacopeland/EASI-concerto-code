const defaultColors = [
  '#3366CC',
  '#DC3912',
  '#FF9900',
  '#109618',
  '#990099',
  '#3B3EAC',
  '#0099C6',
  '#DD4477',
  '#66AA00',
  '#B82E2E',
  '#316395',
  '#994499',
  '#22AA99',
  '#AAAA11',
  '#6633CC',
  '#E67300',
  '#8B0707',
  '#329262',
  '#5574A6',
  '#651067',
];

testRunner.component('participantDetailScores', {
  templateUrl: '/ViewTemplate/EASI-panel-component-participant-detail-scores/html',
  bindings: {
    participant: '=',
  },
  controller: function controller($scope, sessions, scores, $window, auth, $timeout) {
    $scope.participant = null;

    $scope.scoresCollection = [];
    $scope.scoresDataSets = [];

    $scope.tests = [];
    $scope.allTests = [];
    $scope.selectedTestCodes = [];
    $scope.selectedTests = [];
    $scope.testSelections = [];
    $scope.summaryDataSets = [];
    $scope.suppressTestsWatch = false;
    $scope.ongoingFetchesNum = 0;
    $scope.displayEmpty = true;
    $scope.showInitial = 'initial';
    $scope.showRetest = false;
    $scope.query = {
      participantId: null,
      tests: {},
      allTests: 1,
      metrics: {},
      allMetrics: 1,
      iteration: 0,
      datesPreset: 'all',
    };
    $scope.expandables = {
      tests: false,
      summary: true,
      history: false,
      details: true,
    };

    // Gets called when user toggles all tests vs test selection, and show all vs only tests with scores
    $scope.allTestsChanged = function () {
      $scope.suppressTestsWatch = true;
      if ($scope.query.allTests) {
        $scope.query.tests = {};
        $scope.updateCharts();
      } else {
        $scope.query.tests = {};
        angular.forEach($scope.tests, function (test) {
          $scope.query.tests[test.id] = 0;
        });
      }
    };

    $scope.testSelectionChanged = function () {
      let hasSelected = false;

      angular.forEach($scope.query.tests, function (selected) {
        if (selected === 1) {
          hasSelected = true;
        }
      });

      if (hasSelected) {
        $scope.updateCharts();
      }
    };

    $scope.showRetestField = function () {
      if ($scope.showInitial === 'initial') {
        $scope.showRetest = false;
        $scope.query.iteration = 0;
      } else {
        $scope.showRetest = true;
        $scope.query.iteration = 1;
      }
      $scope.fetchScores();
    };
 


    this.$onInit = function () {
      $scope.participant = this.participant;
      $scope.query.participantId = this.participant.id;
      // lets see if I can do only one fetch
      $scope.fetchScores();
    };

    //scores
    let makeScoresDataSet = function () {
      let dataSets = [];
      const metrics = $scope.scoresCollection
        .filter((elem) => $scope.selectedTestCodes.includes(elem.testCode))
        .map((elem) => elem.name)
        .filter((elem, index, self) => self.indexOf(elem) === index);
      for (let i = 0; i < metrics.length; i++) {
        let metric = metrics[i];

        dataSets.push({
          label: metric,
          data: $scope.scoresCollection
            .filter((score) => score.name === metric)
            .map((score) => {
              if (score.name.indexOf('z score') != -1)
                score.value = Math.max(-3, Math.min(score.value, 3));
              return score;
            }),
          parsing: {
            xAxisKey: 'timeCreated',
            yAxisKey: 'value',
          },
          backgroundColor: defaultColors[i],
          borderColor: defaultColors[i],
          color: defaultColors[i],
        });
      }
      $scope.scoresDataSets = dataSets;
    };

    let scoresChart = null;
    let drawScoresChart = function () {
      if (scoresChart !== null) {
        scoresChart.destroy();
        scoresChart = null;
      }

      const elem = document.getElementById('scoresChart');
      if (elem) {
        const ctx = document.getElementById('scoresChart').getContext('2d');
        scoresChart = new Chart(ctx, {
          type: 'line',
          data: {
            datasets: $scope.scoresDataSets,
          },
          options: {
            animation: false,
            scales: {
              y: {
                beginAtZero: true,
              },
              x: {
                type: 'time',
                time: {
                  unit: 'day',
                },
              },
            },
            plugins: {
              legend: {
                labels: {
                  font: {
                    size: 16,
                  },
                },
              },
            },
          },
        });
      }
    };

    //summary
    let makeSummaryDataSet = function () {
      let dataSets = [];
      let summaryScores = [];
      $scope.selectedTests.forEach((test) => {
        if (test.summaryScores !== undefined) {
          let testScores = JSON.parse(test.summaryScores);
          testScores.forEach((testScore) => (testScore.testCode = test.code));
          summaryScores.push(...testScores);
        }
      });
      summaryScores.sort((a, b) => a.order - b.order);

      for (let i = 0; i < summaryScores.length; i++) {
        const summaryScore = summaryScores[i];
        let data = [];
        data = $scope.scoresCollection
          .filter(
            (score) => score.testCode === summaryScore.testCode && score.name === summaryScore.name,
          )
          .map((score) => {
            if (score.name.indexOf('z score') != -1)
              score.value = Math.max(-3, Math.min(score.value, 3));
            score.label = summaryScore.label;
            return score;
          });
        if (data.length === 0 && $scope.displayEmpty) {
          data = [{ value: null, label: summaryScore.label }];
        }

        if (data.length) {
          const color = summaryScore.color ? summaryScore.color : defaultColors[i];
          dataSets.push({
            label: summaryScore.label,
            data: data,
            parsing: {
              xAxisKey: 'value',
              yAxisKey: 'label',
            },
            backgroundColor: color,
            borderColor: color,
            color: color,
          });
        }
      }
      $scope.summaryDataSets = dataSets;
    };

    let summaryChart = null;
    let drawSummaryChart = function () {
      if (summaryChart !== null) {
        summaryChart.destroy();
        summaryChart = null;
      }

      const elem = document.getElementById('summaryChart');
      if (elem) {
        const ctx = document.getElementById('summaryChart').getContext('2d');
        summaryChart = new Chart(ctx, {
          type: 'bar',
          data: {
            datasets: $scope.summaryDataSets,
          },
          options: {
            indexAxis: 'y',
            scales: {
              x: {
                stacked: true,
                min: -3,
                max: 3,
                grid: {
                  color: (t) => {
                    return t.tick.value === 0 ? 'black' : Chart.defaults.borderColor;
                  },
                },
              },
              y: {
                stacked: true,
                ticks: {
                  callback: function (value, index, ticks) {
                    const set = $scope.summaryDataSets[index];
                    return (
                      set.label +
                      (set.data.length > 0 &&
                      set.data[0].value !== null &&
                      !isNaN(set.data[0].value)
                        ? ' = ' + set.data[0].value.toFixed(3)
                        : '')
                    );
                  },
                },
              },
            },
            plugins: {
              legend: {
                display: false,
              },
            },
          },
        });
      }
    };

    // This is a fetch for the template
    $scope.getTestScores = function (testCode, withFeedbackOnly = false) {
      // Return from scoresCollection all rows where the testcode is testcode params and (not withfeedbackonly or e.feedback)
      return $scope.scoresCollection.filter(
        (e) => e.testCode === testCode && (!withFeedbackOnly || e.feedback),
      );
    };

    $scope.fetchScores = function () {
      $scope.ongoingFetchesNum++;
      scores.fetch($scope.query).then((response) => {
        $scope.scoresCollection = response.collection;
        $scope.allTests = response.tests;
        // Test selections are the switches
        if ($scope.testSelections.length === 0) {
          $scope.testSelections = response.tests;
          angular.forEach($scope.testSelections, function (test) {
            if ($scope.query.tests[test.id] === undefined) {
              $scope.query.tests[test.id] = 0;
            }
          });
        }
        $scope.updateCharts();
        $scope.ongoingFetchesNum--;
      });
    };

    $scope.updateCharts = function () {
      $scope.selectedTests =
        $scope.query.allTests === 1
          ? $scope.allTests
          : $scope.allTests.filter((test) => $scope.query.tests[test.id] === 1);

      $scope.selectedTestCodes = $scope.selectedTests.map((test) => test.code);
      makeScoresDataSet();
      drawScoresChart();
      makeSummaryDataSet();
      $timeout(function () {
        requestAnimationFrame(function () {
          drawSummaryChart();
        });
      }, 0);
    };

    $scope.print = function () {
      $window.print();
    };

    $scope.getAdminName = function () {
      if ($scope.scoresCollection && $scope.scoresCollection.length > 0) {
        return $scope.scoresCollection[0].admin_login;
      } else {
        return ' ';
      }
    };
  },
});
