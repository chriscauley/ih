(function() {
  var ICON_CHOICES = [
    'beer',
    'beers',
    'cat-food',
    'cat-feeder',
    'cat-brush',
    'cigarettes',
    'cleaning',
    'dental-floss',
    'drop',
    'dryer',
    'hop',
    'lifeline-in-a-heart-outline',
    'razor',
    'selkirk-rex-cat',
    'shirt',
    'shower',
    'skull',
    'tooth-brush',
    'smoking',
    'washing-machine',
    'washing-plate',
  ];

  var styles = [
    `.fi { background: center no-repeat; background-size: 100% auto; }`,
    ]
  for (var choice of ICON_CHOICES) {
    uR._icons[choice] = "fi fi_"+choice;
    styles.push(`.fi_${choice} { background-image: url(/static/icons/${choice}.png);width: 1em; height: 1em; }`);
  }

  var head = document.head || document.getElementsByTagName('head')[0];
  var style = document.createElement('style');
  style.type = 'text/css';
  if (style.styleSheet){
    style.styleSheet.cssText = styles.join("\n");
  } else {
    style.appendChild(document.createTextNode(styles.join("\n")));
  }
  head.appendChild(style);

  uR.config.name_overrides.icon = function() {
    return {
      type: 'select',
      tagname: 'select-input',
      choices: ICON_CHOICES,
    }
  }
})()
