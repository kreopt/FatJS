var fs = require('fs');
var less = require('less');
var walk = function (sourceDir, targetDir, fileHandler, done) {
    var results = [];
    fs.readdir(sourceDir, function (err, list) {
        if (err) return done(err);
        var pending = list.length;
        if (!pending) return done(null, results);
        list.forEach(function (file) {
            var tgt = targetDir + '/' + file.replace('.less', '.css');
            file = sourceDir + '/' + file;
            fs.stat(file, function (err, stat) {
                if (stat && stat.isDirectory()) {
                    try {
                        fs.mkdirSync(tgt)
                    } catch (e) {
                    }
                    walk(file, tgt, fileHandler, function (err, res) {
                        results = results.concat(res);
                        if (!--pending) done(null, results);
                    });
                } else {
                    results.push(file);
                    fileHandler(sourceDir,file, tgt);
                    if (!--pending) done(null, results);
                }
            });
        });
    });
};

try {
    fs.mkdirSync('./lib')
} catch (e) {
}
try {
    fs.mkdirSync('./lib/css')
} catch (e) {
}
try {
    fs.mkdirSync('./lib/js')
} catch (e) {
}
try {
    fs.mkdirSync('./lib/js/lib')
} catch (e) {
}
walk('./src/less', './lib/css', function (sourceDir,sourcePath, targetPath) {
        var parser = new (less.Parser)({
            paths:[sourceDir], // Specify search paths for @import directives
            filename:sourcePath
        });
        try{
        parser.parse(fs.readFileSync(sourcePath,'utf-8'), function (e, tree) {
            fs.writeFileSync(targetPath, tree.toCSS({ compress:true })); // Minify CSS output
        });
        }catch(e){console.log(e)}
    },
    function (err, results) {
        if (err) throw err;
        console.log(results);
    });
