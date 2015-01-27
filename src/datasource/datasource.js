function Datasource(options) {
    this.options={};
    this.backends={};
    this.configure(options);
}

Datasource.prototype.configure = function(options){
    Object.assign(this.options, options || {});
};

Datasource.prototype.register_backend = function (name, backend) {
    this.backends[name] = backend;
};

Datasource.prototype.fetch = function(sources) {
    var _this = this;
    return Promise.all(sources.map(function(s){
        _this.backends[s.type].fetch(s.fields);
    })).then(function(r){
        var res={};
        for (var rec in r){
            Object.assign(res, rec);
        }
        return res;
    });
};

Fat.register_module('datasource', Datasource);
