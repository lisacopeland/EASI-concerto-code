testRunner.filter("trans", function () {
  return function (name, args = {}) {
    let string = testRunner.R.dictionary[name];
    if(string) {
      for (const [key, value] of Object.entries(args)) { 
        string = string.replaceAll('{{'+key+'}}', value);
      }
      return string;
    }
    return name;
  }
});
