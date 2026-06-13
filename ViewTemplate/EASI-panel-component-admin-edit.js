testRunner.component('adminEdit', {
  templateUrl: "/ViewTemplate/EASI-panel-component-admin-edit/html",
  bindings: {
  },
  controller: function controller($scope, auth, $location, constants) {
    $scope.dictionary = testRunner.R.dictionary;
    $scope.countries = constants.countries;

    $scope.genders = constants.genders;
    $scope.highestDegrees = constants.highestDegrees;
    $scope.professions = constants.professions;
    $scope.user = {}
    $scope.showDate = false // don't show date by default
    $scope.profileLoading = true
    $scope.PaginationToken = null
    $scope.Filter = null

    this.$onInit = function () {
      $scope.refreshUserProfile().then(() => {
        $scope.user = auth.user
        let zeroDate = new Date(0)
        let today = new Date()
        if ($scope.user.expirationDate) {
          $scope.user.expirationDate = new Date($scope.user.expirationDate)
          let weirdDateEliminator = new Date("Thu Jan 01 2000 00:00:00 GMT-0700 (Mountain Standard Time)")
          // I accidentally made "0" date timezoned... fixing here. updateUserProfile will update it :)
          // no user expired before 2000, so any date below that should get set to "0" date
          if ($scope.user.expirationDate < weirdDateEliminator) {
            $scope.user.expirationDate = zeroDate
          }
          if ($scope.user.expirationDate === zeroDate) { // If user expirationDate equals zero date, don't show
            $scope.showDate = false
          }
          else {
            $scope.showDate = true
            // Now, show warning + payment link if expiring within three months
            let expireSoonDate = new Date($scope.user.expirationDate);
            expireSoonDate.setMonth($scope.user.expirationDate.getMonth() - 3); // 3 months

            if (today > expireSoonDate) { // if today is after 3 months back from expiration date
              $scope.showStripeLink = true
            }
            else {
              $scope.showStripeLink = false
            }
          }
        }
        else { // initialize date if it doesn't exist
          $scope.user.expirationDate = zeroDate
          $scope.showDate = false
        }
        $scope.profileLoading = false
        $scope.$apply()
      })
    }

    $scope.updateUserProfile = function () {
      $scope.user.expirationDate = (new Date($scope.user.expirationDate)).toISOString() // Setting expiration date to ISOString for consistancy
      auth.updateUserProfile($scope.user)
    }

    $scope.refreshUserProfile = function () {
      return auth.refreshUserProfile($scope.user)
    }

    $scope.goBack = function () {
      $location.path("/participant");
    }
  }
});
