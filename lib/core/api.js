(function () {
//fallback
    let API = Fat.init_plugin('API', {});
    API.chain = API.call_many;
    inSide.__Register('API', API);

}).call(this);
