!function(){
    'use strict';
    function SimpleDatasource(options){
        this.options=options;
    }
    SimpleDatasource.prototype.fetch=function(ready){
        ready(this.options);
    };
    Fat.register_backend('Datasource','simple', SimpleDatasource);
}();
