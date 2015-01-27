Fat.register_backend('datasource', 'url', {
    replace_placeholders(match, args) {
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
    },
    fetch(data) {
        var info = Fat.router.resolve(window.location.pathname);
        this.replace_placeholders(info.match, data);
        return res;
    }
});
