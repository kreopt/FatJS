!function () {
    var url_patterns = {};
    var url_reverse = {};

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
                    res.match = match;
                    //replace_placeholders(match, res.args);
                    return res;
                }
            }
        }
        return null;
    }

    Fat.router = {
        reverse: function (name, args){
            if (!url_reverse[name]){
                throw new Error('No reverse match found for '+name);
            }
            // TODO: check kw args
            // TODO: check match
            var open = url.indexOf('(');
            var close = -1;
            var url_part;
            var parts=[];
            if (open) {
                url_part = url.substr(close+1, open-close-1);
                this.push(url_part);
                close = url.indexOf(')');
                for (var i = 1; i < args.positional.length; i++) {
                    parts.push(String(args.positional[i]));
                    open = url.indexOf('(', close+1);
                    if (open > 0) {
                        url_part = url.substr(close+1, open-close-1);
                        parts.push(url_part);
                        close = url.indexOf(')');
                    }
                }
                url_part = url.substr(close+1, url.length-close-1);
            } else {
                url_part = url;
            }
            parts.push(url_part);
            return parts.join('');
        },
        resolve: function (url, patterns) {
            if (!patterns) {
                return find_match(url, '', url_patterns);
            } else {
                return find_match(url, '', patterns);
            }
        },
        patterns: function (patterns) {
            Object.assign(url_patterns, patterns);
            for (var pattern in patterns){
                if (patterns[pattern].name) {
                    url_reverse[patterns[pattern].name] = pattern;
                }
            }
        }
    };
}();
