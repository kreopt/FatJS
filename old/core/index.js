!function () {
    class Fat {
        constructor() {
            this.options = {repo: {}};
            this.backends_to_register = {};
            this.plugins = {};
        }

        register_plugin(name, constructor) {
            if (this.plugins[name]) {
                throw 'Failed to register plugin "' + name + '": already exists';
            }
            this.plugins[name] = constructor;
            // fallback
            inSide.__Register(name, constructor);
        }

        init_plugin(plugin_name, options) {
            let instance = new this.plugins[plugin_name](options);
            let backend_list = this.backends_to_register[plugin_name] || {};
            for (let backend_name of Object.keys(backend_list)) {
                instance.register_backend(backend_name, backend_list[backend_name]);
            }
            return instance;
        }

        register_backend(plugin_name, backend_name, constructor) {
            let plugin_backends = this.backends_to_register[plugin_name];
            this.backends_to_register[plugin_name] = plugin_backends || {};
            plugin_backends[backend_name] = constructor;
        }

        register_application(app_name, constructor) {

        }

        init_application(app_name, options) {

        }

        configure(options) {
            this.options = Object.assign(this.options, options);
        }
    }

    window.Fat = new Fat();
}();
