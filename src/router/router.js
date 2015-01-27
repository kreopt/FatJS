!function () {
    var url_patterns = {};

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
