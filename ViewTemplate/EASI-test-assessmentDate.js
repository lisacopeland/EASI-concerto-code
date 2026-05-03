testRunner.controllerProvider.register("assessmentDate", function($scope) {
  let stringToDate = function(string) {
    const elems = string.split("-");
    return new Date(parseInt(elems[0]), parseInt(elems[1]) - 1, parseInt(elems[2]));
  }
  let dateToString = function(date) {
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return year + "-" + (month < 10 ? "0" + month : month) + "-" + (day < 10 ? "0" + day : day);
  }
  
  $scope.values = {
    date: testRunner.R.assessmentDate ? stringToDate(testRunner.R.assessmentDate) : null
  };
  $scope.maxDate = new Date();
  
  testRunner.addExtraControl("assessmentDate", () => dateToString($scope.values.date));
});