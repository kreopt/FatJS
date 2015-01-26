(function(){const Fat = {
    plugins:   {},
    config:    {},
    signals:   new Map(),
    configure: function (options) {
        Object.assign(this.config, options);

        if (jinja && this.config.template_url) {
            jinja.template_url = this.config.template_url;
        }
    }
};
Fat.fetch = function (name) {
    return new Promise(function (resolve, reject) {
        var url = Fat.config.static_url;
        if (!url.endsWith('/')) {
            url += '/';
        }
        url += 'data/' + name + '.json';
        $.ajax({
            type:     "GET",
            url:      url,
            dataType: 'json',
            success:  function (r) {
                resolve(r);
            },
            error:    function (jqXHR, textStatus, errorThrown) {
                reject("API: " + textStatus + " " + errorThrown);
            }
        });
    });
};
window.Fat = Fat;

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
Fat.API = API;

Fat.API.prototype.add_backend('http', {
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

Fat.API.prototype.add_backend('httpjson', {
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
    Fat.API.prototype.add_backend('ws', {
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