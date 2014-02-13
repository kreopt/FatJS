Fat.UI.register_render_engine('ejs', {
    compile: function (template) {
        return ejs.compile(template);
    },
    render: function (compiled, args) {
        return compiled(args);
    }
});
Fat.UI.set_render_engine('ejs');
