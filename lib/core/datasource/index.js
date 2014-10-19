!function () {
    class Datasource extends FatPlugin {
        constructor(backend, options = {}) {
            super(options);
            if (!this.backends[backend]) {
                throw ("Failed to create datasource: backend " + backend + " does not exists");
            }
            this.backend = new this.backends[backend](options);
        }

        fetch(ready) {
            return this.backend.fetch();
        }
    }
    Fat.register_plugin('Datasource', Datasource);
}();
