const Fat = {
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
