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
