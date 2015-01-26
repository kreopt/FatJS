const Fat = {
    plugins:         new Map(),
    config:          {},
    signals:         new Map(),
    configure:       function (options) {
        Object.assign(this.config, options);

        if (jinja && this.config.template_url) {
            jinja.template_url = this.config.template_url;
        }
    },
    register_module: function (name, mod) {
        Object.defineProperty(Fat, name, {value:mod, writable:false});
    },
    register_plugin: function (name, plugin) {
        if (typeof(plugin.init) != 'function') {
            throw "[" + name + "] bad plugin: no init";
        }
        Fat.plugins.set(name, plugin);
    },
    setup_plugins:   function (plugin_names) {
        if (typeof(plugin_names) == typeof("")) {
            plugin_names = [plugin_names];
        }
        for (var plugin of plugin_names) {
            if (this.plugins.has(plugin)) {
                var p = this.plugins.get(plugin);
                p.init(Fat.config.plugins[plugin] || {});
            }
        }
    }
};
Object.defineProperty(Fat.config,'plugins',{
    writable:false,
    value:{}
});
Fat.ajax_get = function(url){
    return new Promise(function(resolve, reject){
        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState == 4) {
                if (xhr.status == 200) {
                    return resolve(xhr.responseText);
                }
                reject({xhr: xhr})
            }
        };
        xhr.send(null);
    });
};
Fat.fetch = function (name) {
    return new Promise(function (resolve, reject) {
        var url = Fat.config.static_url;
        if (!url.endsWith('/')) {
            url += '/';
        }
        url += 'data/' + name + '.json';

        return Fat.ajax_get(url);
    });
};
Fat.add_listener = function (signal, handler, scope) {
    if (!Fat.signals.has(signal)) {
        Fat.signals.set(signal, new Map());
    }
    Fat.signals.get(signal).set(handler, scope);
};

Fat.remove_listener = function (signal, handler) {
    if (!Fat.signals.has(signal)) {
        return;
    }
    Fat.signals.get(signal).delete(handler);
    if (!Fat.signals.get(signal).size) {
        Fat.signals.delete(signal);
    }
};

Fat.emit = function (signal, data) {
    if (Fat.signals.has(signal)) {
        var handler_map = Fat.signals.get(signal);
        for (var entry of handler_map) {
            entry[0].call(entry[1], data);
        }
    }
};

/*
 options framework

 find_domain(domainPath) {
 let keys = domainPath.split(".");
 let domain = this.config;
 while (keys.length > 1) {
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
 let domain = this.config;
 while (keys.length > 1) {
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
 let keyToSet = keys[keys.length - 1];
 let domain = this.find_domain(keys.slice(0, keys.length - 1));
 domain[keyToSet] = value;
 }

 */

window.Fat = Fat;
