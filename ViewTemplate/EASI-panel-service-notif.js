testRunner.service('notif', function ($mdToast) {
  this.getToastTypeIcon = function (type) {
    switch (type) {
      case "error": return "<md-icon style='color: red;'>error</md-icon>";
      default: return "";
    }
  }

  this.toast = function (message, type, position) {
    if (!position) {
      position = "bottom right"
    }
    let icon = this.getToastTypeIcon(type);
    $mdToast.show({
      template: '<md-toast class="md-toast">' + icon + message + '</md-toast>',
      position: position,
      hideDelay: 5000
    });
  };
});
