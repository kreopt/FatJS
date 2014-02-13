// import FatPlugin from 'core/plugin'
class API extends FatPlugin{
    constructor(options){
        this.defaults={
            url:window.location.pathname,
            backend:'http'
        };
        super(options);
    }
    call(signature, args, ready){
        this.backends[this.options.backend].call(this.options, signature, args, ready);
    }
    call_many(requests, ready){
        this.backends[this.options.backend].call_many(this.options, requests, ready);
    }
}
Fat.register_plugin('API',API);