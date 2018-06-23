var ezGulp = require("./ez-gulp");
var argv = require("yargs").argv;

function _app(array) { return array.map(s => "app/"+s) }

var JS_FILES = {
  ih: _app([
    'main.js',
    'icon.js',
    'router.js',
    'task.tag',
    'goal.tag',
    'mode.tag',
    'lap-counter.tag',
  ]),
  ih_test: _app([
    'data.js',
    'tests.js',
  ]),
}

var LESS_FILES = {
  ih: _app(['less/base.less']),
}

var STATIC_FILES = _app([
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
