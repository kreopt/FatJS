class inSide {
    constructor() {
        this.plugin_list={};
        this.config={};
    }

    find_domain(domainPath) {
        let keys = domainPath.split(".");
        let domain=this.config;
        while (keys.length > 1){
            if (!domain.hasOwnProperty(keys[0])) {
                domain[keys[0]] = {};
            }
            domain = domain[keys[0]];
            keys.slice(1);
        }
        return domain;
    }

    get_option(domainPath, defaultVal = null) {
        let keys = domainPath.split(".");
        let domain=this.config;
        while (keys.length > 1){
            if (!domain.hasOwnProperty(keys[0])) {
                return defaultVal;
            }
            domain = domain[keys[0]];
            keys.slice(1);
        }
        return domain[keys[0]];
    }

    set_option(domainPath, value = true) {
        let keys = domainPath.split(".");
        let keyToSet = keys[keys.length-1];
        let domain = this.find_domain(keys.slice(0,keys.length-1));
        domain[keyToSet] = value;
    }

    check_requirements(require_list) {
        for (let name in require_list){
            if (require_list.hasOwnProperty(name) && !(name in this.plugin_list)) {
                return name;
            }
        }
        return null;
    }

    register_error_fatal(name, reason){
        throw('Can not register plugin "'+name+'": '+reason);
    }

    register_plugin(plugin) {
        if (!plugin.hasOwnProperty('__name__')){
            this.register_error_fatal('Unknown', 'No __name__ property specified');
        }
        /*if (!plugin.hasOwnProperty('__version__')){
            this.register_error_fatal(plugin.__name__, 'No __version__ property specified');
        }*/
        if (typeof(plugin.__require__) === typeof([])){
            let failed_name = this.check_requirements(plugin.__require__);
            if (failed_name) {
                this.register_error_fatal(plugin.__name__, 'Missing required "'+failed_name+'"');
            }
        }
        if (plugin.__name__ in this.plugin_list) {
            this.register_error_fatal(plugin.__name__, 'Plugin already registered!');
        }
        this.plugin_list[plugin.__name__] = plugin;
    }
}
