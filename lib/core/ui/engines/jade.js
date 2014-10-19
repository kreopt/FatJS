Fat.UI.addRenderEngine('jade', {
    compile: function (template) {
        return jade.compile(template, {
            pretty: false,
            debug: false,
            compileDebug: false
        });
    },
    render: function (compiled, args) {
        return compiled(args);
    }
});
Fat.UI.setRenderEngine('jade');
