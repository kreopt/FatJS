var gulp = require('gulp');
var jshint = require('gulp-jshint');
var concat = require('gulp-concat');
var rename = require('gulp-rename');
var uglify = require('gulp-uglify');
var traceur = require('gulp-traceur');

const out_file_name = 'fat.min.js';
const out_dir = './';
const source_dir = './src/';
var build_modules = [
  'core/core.js',
  'core/core/index.js',
  'core/core/plugin.js',
  'core/api/index.js',
  'core/api/backends/httpjson.js',
  'core/client.js',
  'core/api.js',
  'core/dom.js',
  'core/windows.js',
  'core/session.js'];

for (var i= 0,len=build_modules.length; i<len;i++){
  build_modules[i]=source_dir+build_modules[i];
}

// Линтинг файлов
gulp.task('lint', function() {
  gulp.src(build_modules)
    .pipe(jshint())
    .pipe(jshint.reporter('default'));
});

// Конкатенация и минификация файлов
gulp.task('minify', function(){
  gulp.src(build_modules)
    .pipe(concat(out_file_name))
    .pipe(traceur({experimental:true}))
    .pipe(uglify({outSourceMap: true}))
    .pipe(gulp.dest(out_dir));
});

gulp.task('watch', function(){

  // Отслеживаем изменения в файлах
  gulp.watch("public/app/**",[/*'lint',*/ 'minify']);

});
// Действия по умолчанию
gulp.task('default', [/*'lint',*/ 'minify', 'watch']);
