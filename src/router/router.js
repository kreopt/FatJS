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
