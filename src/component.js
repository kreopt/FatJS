function Component(name, scope) {
    this.scope = scope || document.body;
}
Component.prototype.init_handlers = function () {
};
Component.prototype.init_connections = function () {
};
Component.prototype.init_styles = function () {
};
Component.prototype.init = function () {
};

Fat.Component = Component;
