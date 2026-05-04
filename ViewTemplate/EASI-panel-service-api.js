testRunner.service('api', function() {
  this.blockingNum = 0;
  this.ongoingNum = 0;
  
  this.action = function(name, params, blocking=true) {
    let service = this;
    if(blocking) this.blockingNum++;
    this.ongoingNum++;
    return new Promise((resolve, reject) => {
      testRunner.runWorker(name, params, response => {
        if(blocking) service.blockingNum--;
        service.ongoingNum--;
        console.log(response, name + " response");
        resolve(response);
      });
    });
  };
  
  this.isBlocked = function() {
    return this.blockingNum > 0;
  }
  
  this.isBusy = function() {
    return this.ongoingNum > 0;
  }
});
