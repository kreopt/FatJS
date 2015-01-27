Fat.register_backend('datasource', 'api', {
    fetch(fields) {
        return Fat.api.call_many(fields);
    }
});
