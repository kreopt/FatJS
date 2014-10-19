Fat.UI.addLoader('string', {
    loadTemplate: function (uiName, template, ready) {
        if (!Fat.UI.templates[uiName]) {
            Fat.UI.templates[uiName] = template;
        }
        ready(Fat.UI.templates[uiName]);
    },
    load_style: function (url, ready) {
    }
});
