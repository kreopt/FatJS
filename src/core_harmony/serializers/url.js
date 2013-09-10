class UrlSerializer extends Serializer {
    _encode(params, prefix=''){
        if (typeof(params)===typeof('')) {
            return params;
        }
        let encoded=[];
        let keyName;
        let encoded_arg;
        for (let key in params) {
            if (params.hasOwnProperty(key)){
                if (typeof(params[key]) !== typeof({})){
                    encoded_arg = key+"="+encodeURIComponent(params[key]);
                } else {
                    keyName=encodeURIComponent(key);
                    if (prefix) {
                        keyName=prefix+"["+keyName+"]";
                    }
                    encoded_arg = this._encode(params[key],keyName);
                }
                encoded.push(encoded_arg);
            }
        }
        encoded.join('&');
        return encoded;
    }

    encode(data){
        return this._encode(data);
    }

    decode(serialized){

    }
}
