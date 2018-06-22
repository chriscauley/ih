var ezGulp = require("./ez-gulp");
var argv = require("yargs").argv;

function src(array) { return array.map(s => "src/"+s) }

var JS_FILES = {
  ih: src([
    'goal.tag',
    'icon.js',
    'lap-counter.tag',
    'main.js',
    'mode.tag',
    'router.js',
    'task.tag',
  ]),
  ih_test: src([
    'data.js',
    'tests.js',
  ]),
}

var LESS_FILES = {
  ih: src(['less/base.less']),
}

var STATIC_FILES = src([
  'icons',
  'data.js',
]);

var PRODUCTION = argv._[0] == 'deploy';

var RENAMES = [
  [`src/img/ih{PRODUCTION?".ico":"-dev.ico"}`,"favicon.ico"]
]

ezGulp({
  js: JS_FILES,
  less: LESS_FILES,
  static: STATIC_FILES,
  renames: RENAMES,
  DEST: ".static/",
  reversion: true,
})