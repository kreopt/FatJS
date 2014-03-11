// import FatPlugin from 'core/plugin'
class API extends FatPlugin {
  constructor(options) {
    this.defaults = {
      url:     window.location.pathname,
      backend: 'http'
    };
    super(options);
  }

  call(signature, args) {
    return new Promise(function(resolve, reject){
      this.backends[this.options.backend].call(this.options, signature, args, resolve, reject);
    });
  }

  call_many(requests) {
    return new Promise(function(resolve, reject){
      this.backends[this.options.backend].call_many(this.options, requests, resolve, reject);
    });
  }
}
Fat.register_plugin('API', API);
