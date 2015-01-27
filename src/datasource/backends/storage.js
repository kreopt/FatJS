Fat.register_backend('datasource', 'local_storage', {
    fetch(fields) {
        var r = {};
        for (var field of fields){
            r[field] =  localStorage.getItem(field);
        }
    }
});
Fat.register_backend('datasource', 'session_storage', {
    fetch(fields) {
        var r = {};
        for (var field of fields){
            r[field] =  sessionStorage.getItem(field);
        }
    }
});