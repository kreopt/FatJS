class UrlSerializer {
    stringify(data, prefix = '') {
        if (typeof(data) === typeof('')) {
            return data;
        }
        let encoded = [];
        let keyName;
        let encoded_arg;
        for (let key of Object.getOwnPropertyNames(data)) {
            if (typeof(data[key]) !== typeof({})) {
                encoded_arg = key + "=" + encodeURIComponent(data[key]);
            } else {
                keyName = encodeURIComponent(key);
                if (prefix) {
                    keyName = prefix + "[" + keyName + "]";
                }
                encoded_arg = this.encode(data[key], keyName);
            }
            encoded.push(encoded_arg);
        }
        return encoded.join('&');
    }

    parse_key(key, object, value) {
        let first_key = key.substr(0, key.indexOf('['));
        if (!first_key) {
            object[first_key] = value;
            return;
        }
        object[first_key] = object[first_key] || {};
        let key_rest = key.substr(first_key.length + 1);
        parse_key(key_rest.substr(0, key_rest.indexOf(']')) + key_rest.substr(key_rest.indexOf(']') + 1), object[first_key], value);
    }

    parse(serialized) {
        if (!serialized) {
            return {};
        }
        let hashes = serialized.split('&');
        let vars = {};
        let key;
        let val;
        for (let i = 0, len = hashes.length; i < len; i++) {
            [key, val] = decodeURIComponent(hashes[i]).split('=');
            this.parse_key(key, vars, val);
        }
        return vars;
    }
}
