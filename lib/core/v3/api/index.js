// import FatPlugin from 'core/plugin'
!function() {
    function API(options) {
        this.options = options || {};
        this.defaults = {
            url:     window.location.pathname,
            backend: 'httpjson'
        };
        this.options = $.extend(this.defaults, this.options);
    }
    API.prototype.backends={};
    API.prototype.add_backend = function(name, backend){
        API.prototype.backends[name] = backend;
    };
    API.prototype.call = function(signature, args) {
        return API.prototype.backends[this.options.backend].call(this.options.url, signature, args);
    };

    API.prototype.call_many = function(requests) {
        return API.prototype.backends[this.options.backend].call_many(this.options.url, requests);
    };
    Fat.API = API;
}();
