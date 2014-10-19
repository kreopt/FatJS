(()-> {
    /*
     Именование сигналов:
     sigName ::= [typeDescriptor] [a-zA-Z._]+
     typeDescriptor ::= [=]{,1}
     Типы:
     sigName - простой сигнал. подписка является постоянной
     =sigName - временный сигнал. подписка уничтожается после вызова
     * - любой сигнал
     */

    // TODO: content-based pub/sub

    const SIGNAL_MODIFIERS = ['=', '*'];

    let connection_table = {};

    function parse_signal(signature) {
        [signal, emitter] = signature.split(':');
        return {
            name: signal.replace(new RegExp('[' + SIGNAL_MODIFIERS.join('') + ']'), ''),
            emitter: emitter,
            modifier: SIGNAL_MODIFIERS.indexOf(signal[0]) > -1 ? signal[0] : ''
        };
    };

    function validate_signal(signal) {
        if (!(signal === '*' || signal.match('^[' + SIGNAL_MODIFIERS.join('') + ']?[a-zA-Z][a-zA-Z_.0-9]*$'))) {
            throw 'Bad signal name: ' + signal;
        }
    };

    function add_connection(signature, handler_name, receiver, handler_func) {
        let objectName = receiver ? receiver.__id__ : 'unnamed';
        connection_table[signature] = connection_table[signature] || {};
        connection_table[signature][objectName] = connection_table[signature][objectName] || {instance: receiver, handlers: {}};
        connection_table[signature][objectName].handlers[handler_name] = handler_func ? handler_func : receiver[handler_name];
        return handler_name;
    };

    function has_domain(object, domains) {
        let current_object = object;
        for (let i = 0, len = domains.length; i < len; i++) {
            if (!current_object.hasOwnProperty(domains[i])) return false;
            current_object = current_object[domains[i]];
        }
        return true;
    };

    function remove_connection(signature, handler_name, receiver) {
        let object_name = receiver.__id__;
        if (signature === '*') {
            for (let sig in connection_table) {
                if (has_domain(connection_table, [sig, object_name])) {
                    delete connection_table[sig][object_name];
                    if (!Object.keys(connection_table[sig]).length) {
                        delete connection_table[sig];
                    }
                }
            }
        } else if (has_domain(connection_table, [signature, object_name])) {
            delete connection_table[signature][object_name].handlers[handler_name];
            if (!Object.keys(connection_table[signature][object_name]).length) {
                delete connection_table[signature][object_name];
                if (!Object.keys(connection_table[signature]).length) {
                    delete connection_table[signature];
                }
            }
        }
    };

    function invoke(signal, data = {}, emit_result = false) {
        let signal_info = parse_signal(signal);
        let is_temporary = signal_info.modifier === '=';

        if (!connection_table[signal]) return;

        let connection_list = connection_table[signal];
        data.__signal__ = signal_info.name;
        for (let app_name in connection_list) {
            let connection = connection_list[app_name];
            for (let handler_name in connection.handlers) {
                res = connection.handlers[handler_name].call(connection.instance, data, signal_info.emitter);
                if (emit_result && res !== null) {
                    EMIT('=' + signal_info.name, res);
                }
                if (is_temporary) {
                    remove_connection('=' + signal_info.name, handler_name, connection.instance);
                }
            }
        }
    };

    self.DISCONNECT = function (signal, handler, receiver) {
        validate_signal(signal);
        return remove_connection(signal, handler, receiver);
    };

    self.CONNECT = function (signal, handler, receiver) {
        let handler_func;
        validate_signal(signal);
        if (typeof handler === typeof (()-> {
        })) {
            handler_func = handler;
            handler = inSide.__nextID();
        } else {
            if (receiver[handler] == null) {
                console.log('failed to connect: ' + signal + ' -> ' + handler);
                throw "No such slot: " + handler;
            }
        }
        return add_connection(signal, handler, receiver, handler_func);
    };

    self.EMIT = function (signal, data = {}, emit_result = false) {
        validate_signal(signal);
        invoke(signal, data, emit_result);
    };

    self.INIT_CONNECTIONS = function (scope, connection_list) {
        for (let signal in connection_list) {
            CONNECT(signal, connection_list[signal], scope);
        }
    };

})();
