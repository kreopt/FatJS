!function(){
    // TODO: mutation observer
    function CallPubSub() {
        this._connectionTable = {};
    }

    CallPubSub.prototype._connect_one = function (scope, signal, handler, argList) {
        if (!this._connectionTable[signal]) {
            this._connectionTable[signal] = {};
        }
        this._connectionTable[signal][scope.__pubsub_id__]=$(scope);
        $(scope).on(signal,scope[handler]);
    };
    CallPubSub.prototype._connect_many = function (scope, sigHandlers, argList) {
        for (var sig in Object.keys(sigHandlers)) {
            this._connect_one(scope, sig, sigHandlers[sig], argList);
        }
    };
    CallPubSub.prototype.connect = function (scope, signal, handler, argList) {
        var single = typeof(signal) === typeof('');
        var many = typeof(signal) === typeof({});

        if (!(single || many)) {
            return console.error('Connect', signal, 'Signal is not a string or an object');
        }
        if (typeof(scope) !== typeof({})) {
            return console.error('Connect', signal, 'Scope is not an object');
        }
        if (typeof(scope.__pubsub_id__) !== typeof(0)) {
            return console.error('Connect', signal, 'Unnamed scope');
        }
        if (single) {
            this._connect_one(scope, signal, handler, argList);
        } else {
            this._connect_many(scope, signal, argList);
        }
        return null;
    };
    CallPubSub.prototype.disconnect = function (scope, signal, handler) {
        try {
            if (handler) {
                delete this._connectionTable[signal][scope.__pubsub_id__];
            } else {
                for (var sig in Object.keys(this._connectionTable)) {
                    if (this._connectionTable[sig][scope.__pubsub_id__]) {
                        delete this._connectionTable[sig][scope.__pubsub_id__];
                    }
                    if (Object.keys(this._connectionTable[sig]).length === 0) {
                        delete this._connectionTable[sig];
                    }
                }
            }
            $(scope).off(signal, scope[handler]);
        } catch (e) {
            this._error('Disconnect', signal, e);
        }
    };
    CallPubSub.prototype.emit = function (signal, data) {
        if (this._connectionTable[signal]) {
            for (var scopeName in Object.keys(this._connectionTable[signal])) {
                this._connectionTable[signal][scopeName].triggerHandler(signal, data);
            }
        }
    };
    Fat.register_backend('PubSub', 'call', CallPubSub);
}();
