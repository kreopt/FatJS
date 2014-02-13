!function(){
    "use strict";
    function Datasource(backend, options) {
        if (!options){
            options = {}
        }
        if (!this.backends[backend]){
            throw ("Failed to create datasource: backend "+backend+" does not exists")
        }
        Object.defineProperty(this, 'backend',{
            value:new this.backends[backend](options)
        })
    }
    Datasource.prototype = Object.create(Fat['Factory'].prototype);
    Object.defineProperties(Datasource.prototype, {
        fetch: {value:function(ready){
            this.backend.fetch(ready)
        }}
    });
    Fat.register_plugin('Datasource', Datasource);
}();
