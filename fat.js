(function(){const Fat = {
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

function API(options) {
    this.options = options || {};
    this.defaults = {
        url:     window.location.pathname,
        backend: 'httpjson'
    };
    this.options = $.extend(this.defaults, this.options);
}
API.prototype.backends = {};
API.prototype.add_backend = function (name, backend) {
    API.prototype.backends[name] = backend;
};
API.prototype.call = function (signature, args) {
    return API.prototype.backends[this.options.backend].call(this.options.url, signature, args);
};

API.prototype.call_many = function (requests) {
    return API.prototype.backends[this.options.backend].call_many(this.options.url, requests);
};
Fat.register_module('api', API);

Fat.api.prototype.add_backend('http', {
    call: function (url, signature, data) {
        return new Promise(function(resolve, reject){
            $.ajax({
                type: "POST",
                url: url,
                data: {signature: signature, data: data},
                dataType: 'json',
                success: function(r){
                    resolve(r);
                },
                error: function(jqXHR, textStatus, errorThrown){
                    reject("API: "+textStatus+" "+errorThrown);
                }
            });
        });

    },
    call_many: function (url, requests) {
        return new Promise(function(resolve, reject) {
            $.ajax({
                type:    "POST",
                url:     url,
                data:    {requests: requests},
                dataType: 'json',
                success: function (r) {
                    resolve(r);
                },
                error: function(jqXHR, textStatus, errorThrown){
                    reject("API: "+textStatus+" "+errorThrown);
                }
            });
        });
    }
});

Fat.api.prototype.add_backend('httpjson', {
    call: function (url, signature, data) {
        return new Promise(function(resolve, reject){
            $.ajax({
                type: "POST",
                url: url,
                data: JSON.stringify({signature: signature, data: data}),
                dataType: 'json',
                success: function(r){
                    resolve(r);
                },
                error: function(jqXHR, textStatus, errorThrown){
                    reject("API: "+textStatus+" "+errorThrown);
                }
            });
        });

    },
    call_many: function (url, requests) {
        return new Promise(function(resolve, reject) {
            $.ajax({
                type:    "POST",
                url:     url,
                data:    JSON.stringify({requests: requests}),
                dataType: 'json',
                success: function (r) {
                    resolve(r);
                },
                error: function(jqXHR, textStatus, errorThrown){
                    reject("API: "+textStatus+" "+errorThrown);
                }
            });
        });
    }
});

!function () {
    var seq = 0;
    var state = null;
    var ws = null;
    var promises = {};
    var queue = [];
    var timeout = 100;

    var init = function (url) {
        ws = new WebSocket(url);
        ws.onopen = function () {
            state = 1;
            console.debug('connected');
            timeout = 100;
            while (queue.length) {
                send.apply(this, queue.splice(0, 1)[0]);
            }
        };
        ws.onclose = function () {
            state = null;
            console.log('Соединение потеряно, восстанавливаем...');
            setTimeout(function () {
                timeout *= 2;
                init(url);
            }, timeout);
        };
        ws.onmessage = function (evt) {
            var msg = JSON.parse(evt.data);
            console.debug('RECV>', msg);
            if (promises[msg.seq]) {
                if (!msg.status) {
                    promises[msg.seq].resolve(msg.data);
                } else {
                    promises[msg.seq].reject(msg.data);
                }
                delete promises[msg.seq];
            }
        };
    };
    var send = function (data, ready, options) {
        promises[seq] = ready;
        data.seq = seq;
        if (options.gen_head) {
            data.head = options.gen_head();
        }
        console.debug('SEND>', data);
        ws.send(JSON.stringify(data));
        seq++;
    };
    Fat.api.prototype.add_backend('ws', {
        call: function (options, signature, data) {
            var ready = new Promise();
            if (!state) {
                queue.push([
                    {signature: signature, data: data},
                    ready,
                    options
                ]);
                init(options.url);
            } else {
                send({signature: signature, data: data}, ready, options);
            }
        },
        call_many: function (options, requests) {
            var ready = new Promise();
            if (!state) {
                queue.push([
                    {requests: requests},
                    ready,
                    options
                ]);
                init(options.url);
            } else {
                send({requests: requests}, ready, options);
            }
        }
    });
}();

Fat.url = {
    stringify:function(data, prefix = '') {
        if (typeof(data) === typeof('')) {
            return data;
        }
        var encoded = [];
        var keyName;
        var encoded_arg;
        for (var key of Object.getOwnPropertyNames(data)) {
            if (typeof(data[key]) !== typeof({})) {
                encoded_arg = key + "=" + encodeURIComponent(data[key]);
            } else {
                keyName = encodeURIComponent(key);
                if (prefix) {
                    keyName = prefix + "[" + keyName + "]";
                }
                encoded_arg = Fat.stringify(data[key], keyName);
            }
            encoded.push(encoded_arg);
        }
        return encoded.join('&');
    },

    parse_key: function(key, object, value) {
        var first_key = key.substr(0, key.indexOf('['));
        if (!first_key) {
            object[first_key] = value;
            return;
        }
        object[first_key] = object[first_key] || {};
        var key_rest = key.substr(first_key.length + 1);
        parse_key(key_rest.substr(0, key_rest.indexOf(']')) + key_rest.substr(key_rest.indexOf(']') + 1), object[first_key], value);
    },

    parse: function(serialized) {
        if (!serialized) {
            return {};
        }
        var hashes = serialized.split('&');
        var vars = {};
        var key;
        var val;
        for (var i = 0, len = hashes.length; i < len; i++) {
            [key, val] = decodeURIComponent(hashes[i]).split('=');
            this.parse_key(key, vars, val);
        }
        return vars;
    }
};

!function () {
    var url_patterns = {};

    function replace_placeholders(match, args) {
        if (!args) {
            return;
        }
        var match_place;
        for (var i = 0, keys = Object.keys(args), len = keys.length; i < len; i++) {
            var arg = keys[i];
            if (typeof args[arg] === 'object') {
                replace_placeholders(match, args[arg]);
            } else if (typeof args[arg] === 'string') {
                match_place = args[arg].match(new RegExp('\\$(\\d+)', ''));
                if (match_place) {
                    args[arg] = match[Number(match_place[1])];
                }
            }
        }
    }

    function find_match(url, prefix, patterns, matches) {
        var match;
        if (!matches) {
            matches = [];
        }
        for (var pattern in patterns) {
            match = url.match(new RegExp(prefix + pattern, ''));
            if (match) {
                if (patterns[pattern].patterns) {
                    return find_match(url, prefix + pattern, patterns[pattern].patterns, matches);
                } else {
                    var res = Object.assign({}, patterns[pattern]);
                    res.pattern = pattern;
                    res.url = url;
                    //replace_placeholders(match, actionInfo.args);
                    //return actionInfo;
                    return res;
                }
            }
        }
        return null;
    }

    Fat.router = {
        resolve: function (url, patterns) {
            if (!patterns) {
                return find_match(url, '', url_patterns);
            } else {
                return find_match(url, '', patterns);
            }
        },
        patterns: function (patterns) {
            Object.assign(url_patterns, patterns);
        }
    };
}();

Fat.render = function ($elements, template, data) {
    return new Promise(function (resolve, reject) {
        jinja.render('{% include "' + template + '" %}', data).then(function (html) {
            // TODO: mb make sure elements are empty
            for (var i = 0; i < $elements.length; i++) {
                $elements[i].innerHTML = html;
            }
            resolve();
        });
    });
}

!function(){
    const reverse={};
    const urls = {};

    Fat.urls=function urls(urls){

    };

    function make_reverse(){}
    make_reverse();

    jinja.make_tag('url',function(stmt){
        var tokens=stmt.split(' ');
        var url = tokens[0].substr(1,tokens[0].length-2);

        var open = url.indexOf('(');
        var close = -1;
        var url_part;
        if (open) {
            url_part = url.substr(close+1, open-close-1);
            this.push(url_part);
            close = url.indexOf(')');
            for (var i = 1; i < tokens.length; i++) {
                this.push('get(' + tokens[i] + ')');
                open = url.indexOf('(', close+1);
                if (open > 0) {
                    url_part = url.substr(close+1, open-close-1);
                    this.push(url_part);
                    close = url.indexOf(')');
                }
            }
            url_part = url.substr(close+1, url.length-close-1);
        } else {
            url_part = url;
        }
        this.push(url_part);
    });

    jinja.make_tag('static',function(stmt){
        stmt = stmt.trim();
        this.push("write(\""+Fat.config.static_url + stmt.substr(1,stmt.length-2)+"\")");
    });
}();
}());
//# sourceMappingURL=fat.js.map