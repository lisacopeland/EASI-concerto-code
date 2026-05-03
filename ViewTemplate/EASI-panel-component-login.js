testRunner.component('panelLogin', {
  templateUrl: "/ViewTemplate/EASI-panel-component-login/html",
  bindings: {
    item: '='
  },
  controller: function controller($scope, api, notif, auth, transFilter) {
    $scope.dictionary = testRunner.R.dictionary;
    $scope.return = testRunner.R.return;

    this.$onInit = function () {
      const params = new URLSearchParams(window.location.search)
      let code = params.get('code')

      if (code) {
        auth.logInWithCode(code).then(response => {
          if (response.user) {
            if (!response.user.name || !response.user.profession || !response.user.highestDegree) {
              notif.toast(transFilter('panel_login_toast_update_profile', { login: response.user.login }));
            }
            else {
              notif.toast(transFilter('panel_login_toast_welcome', { login: response.user.login }));
            }
            $scope.$apply();
          }
        })
      }
    }
    $scope.api = api;
    $scope.logIn = function () {
      auth.logIn($scope.login, $scope.password).then(response => {
        if (!response.user) { // Login Issue
          console.log(response)
          if (response.error.id === -2) { // General error
            notif.toast(transFilter('panel_login_error_general'), 'error', 'end right')
          }
          else if (response.error.id === -3) { // email not validated, redirect user to do that
            notif.toast(transFilter('panel_login_error_not_validated'), 'error', 'end right')
            window.location.href = "https://login.easitests.com/oauth2/authorize?client_id=6bbto14uknbbc4p2va7uvih8ac&response_type=code&scope=aws.cognito.signin.user.admin+email+openid+phone+profile&redirect_uri=https%3A%2F%2Fwww.easitests.com%2Ftest%2Fpanel";
          }
          else if (response.error.id === -1) {
            if (response.error.status_code === 400) { // invalid password
              notif.toast(transFilter('panel_login_error_incorrect'), 'error', 'end right')
            }
            else { // some other error.
              notif.toast(transFilter('panel_login_error_general'), 'error', 'end right')
            }
          }
        } else { // You're in!
          todayDate = new Date()
          $scope.showDate = true
          userExpireDate = response.user.expirationDate
          // Now, show warning if expiring within three months
          if (!userExpireDate) { // if it's blank, set the expire date to a year from now, so it never thinks you're expiring
            // this usually means you're an admin?
            // FIXME: Tie this to admin, not to nullDate
            userExpireDate = new Date(todayDate) // clone today so i don't edit it
            userExpireDate = userExpireDate.setMonth(todayDate.getMonth() + 12)
          }
          else {
            userExpireDate = new Date(response.user.expirationDate)
          }

          // expireSoonDate is three months before you expire
          let expireSoonDate = new Date(userExpireDate);
          expireSoonDate.setMonth(userExpireDate.getMonth() - 3); // 3 months

          if (userExpireDate < todayDate) { // expirationDate lessthan (before) today, so redirect to stripe
            notif.toast(transFilter('panel_login_toast_expired_subscription', { login: response.user.login }), 'error')
            window.setTimeout(function () {
              window.location.href = `https://buy.stripe.com/fZeaHlbAK8i0gEg145?prefilled_email=${response.user.email}`;
            }, 5000);
          }
          else if (todayDate > expireSoonDate) { // if today is after 3 months back from expiration date, show update subscription warning
            notif.toast(transFilter('panel_login_toast_update_subscription', { login: response.user.login }), 'warning')
          }
          else if (!response.user.name || !response.user.profession || !response.user.highestDegree) {
            notif.toast(transFilter('panel_login_toast_update_profile', { login: response.user.login }), 'warning')
          }
          else {
            notif.toast(transFilter('panel_login_toast_welcome', { login: response.user.login }));
          }
        }
        $scope.$apply();
      })
    }
  }
});