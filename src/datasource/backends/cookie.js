Fat.register_backend('datasource', 'cookie', {
    getCookie(name) {
      var matches = document.cookie.match(new RegExp(
        "(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
      ));
      return matches ? decodeURIComponent(matches[1]) : undefined;
    },
    fetch(fields) {
        var r = {};
        for (var field of fields){
            r[field] =  this.getCookie(field);
        }
    }
});