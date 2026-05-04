testRunner.service('auth', function (api, $cookies, $rootScope) {
    this.user = null;
    this.token = null;
    this.isExpired = null;
    // Private Functions
    this._checkExpiration = function (user, token) {
        let todayDate = new Date();
        let isExpired = false;

        //if user is an admin (clasi team) and exists, set expiration date to be null 
        if (user.type == 1 && user.expirationDate !== null) {
            user.expirationDate == null;
        }
        user.expirationDate = new Date(user.expirationDate);

        // Now that we've normalized date, we can check to see if the user is expired:
        if (user.expirationDate === null) { // People who don't expire get their expiration date set to null
            isExpired = false;
        }
        else if (user.expirationDate < todayDate) { // expirationDate lessthan (before) today, so flag it
            isExpired = true;
        }

        console.log("expiration date", user.expirationDate);
        console.log("isExpired", { isExpired });
        return {
            user,
            token,
            isExpired
        }
    }
    this._expireUser = function () {
        // if you're expired, let user renew subscription, but don't let them do anything else somehow...
        this.logOut() // FIXME: Do something other than logging users out
    }

    this._handleLoginGenerator = function (self) {
        return (response) => { // callback to generically handle login regardless of login method
            if (response.user !== null && response.token !== null) {
                checkExpirationOutput = self._checkExpiration(response.user, response.token) // Formats and check expiration date on the returned user object

                self.isExpired = checkExpirationOutput.isExpired;
                self.user = checkExpirationOutput.user;
                self.token = checkExpirationOutput.token;

                if (self.isExpired) { self._expireUser(); }
                else {
                    self.createTokenCookie();
                    $rootScope.$apply();
                    /* @TODO commented out as it kept logging out admin */
                    self.refreshUserProfile(self.user).then(() => {
                        $rootScope.$apply()
                    })
                    if (!testRunner.R.languageQuery && self.user.languageCode !== null && self.user.languageCode !== testRunner.R.language) {
                        self.changeLanguage(self.user.languageCode);
                    }
                }
            }
            return response;
        }
    }
    // Public Functions
    this.getTherapists = function (PaginationToken, Filter) {
        return api.action("getTherapists", {
            PaginationToken,
            Filter
        });
    }

    this.getTokenCookie = function () {
        const token = $cookies.get("easiToken");
        return token ? token : null;
    }

    this.createTokenCookie = function () {
        let expiryDate = new Date();
        expiryDate.setHours(expiryDate.getHours() + 22);
        $cookies.put("easiToken", this.token, { expires: expiryDate }); // TODO: Maybe use cognito token, i dunno.
    };

    this.removeTokenCookie = function () {
        $cookies.remove("easiToken");
    }

    this.isAuthorized = function () {
        return this.user !== null;
    };

    this.logIn = function (login, password) {
        return api.action('logIn', {
            login: login,
            password: password
        }).then(this._handleLoginGenerator(this));
    };

    this.logInWithCode = function (code) { // Login with code happens when you're redirected from a Cognito login flow
        return api.action('logInWithCode', {
            code: code
        }).then(this._handleLoginGenerator(this));
    };

    this.logInWithToken = function (token) {
        return api.action('logInWithToken', {
            token: token
        }).then(this._handleLoginGenerator(this));
    }

    this.changeLanguage = function (lang) {
        location.href = "?lang=" + lang + location.hash;
    }

    // ADDED
    this.updateUserProfile = function (user) {
        this.user = user
        return api.action('updateUserProfile', { user: this.user, token: this.token }).then(response => {
            this.user = response.user;
            this.token = response.token;
        });
    }
    this.refreshUserProfile = function (user) {
        this.user = user
        return api.action('refreshUserProfile', { user: this.user, token: this.token }).then(response => {
            this.user = response.user;
            this.token = response.token;
        });
    }
    // END ADDED
    this.logOut = function () {
        return api.action('logOut', {}).then(response => {
            this.user = null;
            this.token = null;
            this.removeTokenCookie();
            return response;
        });
    };

    this.token = this.getTokenCookie();
    if (this.token !== null && this.user === null) {
        this.logInWithToken(this.token);
    }
});
