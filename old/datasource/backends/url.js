!function () {
    class UrlDatasource {
        constructor(options) {
            this.options = options;
        }

        fetch() {
            var info = Fat.Url.resolve(window.location.pathname + window.location.hash, this.options);
            return Promise.cast(info.args);
        }
    }
    Fat.register_backend('Datasource', 'url', UrlDatasource);
}();
