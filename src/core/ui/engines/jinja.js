Fat.UI.addRenderEngine('jinja',{
    compile: function (template) {
        return jinja.compile(template).render;
    },
    render: function (compiled, args) {
        return compiled(args);
    }
});
Fat.UI.setRenderEngine('jinja');
