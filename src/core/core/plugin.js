class FatPlugin {
    constructor(options) {
        this.backends = {};
        this.options = Object.assign(this.defaults, options || {});
    }

    register_backend(name, constructor) {
        this.backends[name] = constructor;
    }

    configure(new_options) {
        this.options = Object.assign(this.options, new_options || {});
    }
}