class Mode extends uR.db.Model {
  constructor(opts={}) {
    opts._is_api = true;
    super(opts);
  }
  __str() {
    return this.name;
  }
}

class ModeChange extends uR.db.Model {
  constructor(opts={}) {
    opts._is_api = true;
    super(opts);
  }
  __str() {
    return this.mode.name;
  }
}

uR.db.register("ih",[Mode,ModeChange])

ih.getLastModeChange = function() {
  var changes = uR.db.ih.ModeChange.objects.all()
  return changes && changes[changes.length-1] || { mode: { name: "No last change!" } };
}

<mode-widget onclick={ openViewer } class="pointer">
  <div>{ last_change && last_change.mode.name }</div>

  <script>
this.on("route",function() {
  this.last_change = ih.getLastModeChange();
})
openViewer(e) {
  uR.route("/modechange/");
}
  </script>
</mode-widget>

<mode-viewer class={ className }>
  <a class="card card-body pointer" href="/">Home</a>
  <div class="card pointer" onclick={ setMode } each={ mode,i in modes }>
    <div class="card-body">
      <i class={ uR.icon("star") } if={ mode == last_change.mode }></i>
      { mode.name }
    </div>
  </div>
  <a href={ uR.db.ih.Mode.admin_new_url } class="card">
    <div class="card-body">
      <i class={ uR.icon("plus") }></i>
      Add new Mode
    </div>
  </a>

  <script>
this.on("route",function() {
  this.update(); //#! this is clunky... should be happening automatically!
});
this.on("update", function() {
  this.last_change = ih.getLastModeChange();
  this.modes = uR.db.ih.Mode.objects.all()
})
setMode(e) {
  this.ajax({
    url: "/api/schema/ih.ModeChangeForm/",
    method: "POST",
    data: { mode: e.item.mode.id, created: moment().format("YYYY-MM-DD HH:mm") },
    success: function(data) {
      new uR.db.ih.ModeChange({values_list: data.values_list});
      console.log(this);
      this.update();
    },
  });
}
  </script>
</mode-viewer>