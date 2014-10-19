// import FatPlugin from 'core/plugin'
class API extends FatPlugin {
    constructor(options) {
        this.defaults = {
            url: window.location.pathname,
            backend: 'http'
        };
        super(options);
    }

    call(signature, args) {
        return this.backends[this.options.backend].call(this.options, signature, args);
    }

    call_many(requests) {
        return this.backends[this.options.backend].call_many(this.options, requests);
    }
}
Fat.register_plugin('API', API);
