function API(options) {
    this.defaults = {
        url:     window.location.pathname,
        backend: 'httpjson'
    };
    this.configure(options);
}
API.prototype.backends = {};
API.prototype.configure = function(options){
    this.options = Object.assign(this.defaults, options || {});
};
API.prototype.register_backend = function (name, backend) {
    API.prototype.backends[name] = backend;
};
API.prototype.call = function (signature, args) {
    return API.prototype.backends[this.options.backend].call(this.options.url, signature, args);
};

API.prototype.call_many = function (requests) {
    return API.prototype.backends[this.options.backend].call_many(this.options.url, requests);
};
Fat.register_module('api', API);
