!function(){
    'use strict';
    function UrlDatasource(options){
        this.options=options;
    }
    UrlDatasource.prototype.fetch=function(ready){
        var info = Fat.Url.resolve(window.location.pathname+window.location.hash, this.options);
        ready(info.args);
    };
    Fat.register_backend('Datasource','url', UrlDatasource);
}();
