var gulp = require('gulp');
var concat = require('gulp-concat');
var rename = require('gulp-rename');
var uglify = require('gulp-uglify');
var wrap = require('gulp-wrap');
var sourcemaps = require('gulp-sourcemaps');
var es6to5 = require('gulp-6to5');

const out_file_name = 'fat.js';
const out_file_name_min = 'fat.min.js';
const out_dir = './';
const source_dir = './src/';
var build_modules = [
    'core.js',
    'serializers/*.js',
    'router/*.js',
    'api/api.js',
    'api/backends/*.js',
    'datasource/datasource.js',
    'datasource/backends/*.js',
    'template.js',
    'templatetags/*.js'
];

for (var i = 0, len = build_modules.length; i < len; i++) {
    build_modules[i] = source_dir + build_modules[i];
}

// Конкатенация и минификация файлов
gulp.task('minify', function(){
    gulp.src(build_modules)
        .pipe(sourcemaps.init())
        .pipe(concat(out_file_name_min))
        .pipe(wrap('(function(){<%= contents %>}());'))
        .pipe(es6to5())
        .pipe(uglify({outSourceMap: true}))
        .pipe(sourcemaps.write(out_dir))
        .pipe(gulp.dest(out_dir));
});

gulp.task('build', function(){
    gulp.src(build_modules)
        .pipe(sourcemaps.init())
        .pipe(concat(out_file_name))
        .pipe(wrap('(function(){<%= contents %>}());'))
        .pipe(sourcemaps.write(out_dir))
        .pipe(gulp.dest(out_dir));
});

gulp.task('watch', function(){

    // Отслеживаем изменения в файлах
    gulp.watch("src/**",['build', 'minify']);

});
// Действия по умолчанию
gulp.task('default', ['minify', 'build', 'watch']);
