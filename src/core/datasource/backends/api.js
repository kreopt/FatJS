!function(){
    'use strict';
    function ApiDatasource(options){
        this.options=options;
    }
    ApiDatasource.prototype.fetch=function(ready){
        Fat.API.call_many(this.options, ready)
    };
    Fat.register_backend('Datasource','api', ApiDatasource);
}();
