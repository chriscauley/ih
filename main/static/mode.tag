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
  return changes && changes[changes.length-1] || { mode: { name: "Mode not set!" } };
}

<mode-widget onclick={ openViewer } class="pointer">
  <div>{ last_change && last_change.mode.name }</div>

  <script>
this.on("route",function() {
  this.last_change = ih.getLastModeChange();
})
openViewer(e) {
  uR.route("/mode/");
}
  </script>
</mode-widget>

<mode-viewer class={ className }>
  <a class="card card-body pointer" href="/">Home</a>
  <ur-tabs>
    <ur-tab title="Change Mode">
      <div class="card pointer" onclick={ ih.setMode } each={ mode,i in ih.modes }>
        <div class="card-body">
          <i class={ uR.icon("star") } if={ mode == ih.last_change.mode }></i>
          { mode.name }
        </div>
      </div>
      <a href={ uR.db.ih.Mode.admin_new_url } class="card">
        <div class="card-body">
          <i class={ uR.icon("plus") }></i>
          Add new Mode monkey
        </div>
      </a>
    </ur-tab>
    <ur-tab title="History">
      Yay history!
    </ur-tab>
  </ur-tabs>

  <script>
this.on("route",function() {
  this.update(); //#! this is clunky... should be happening automatically!
  ih.setMode = e => this.setMode(e)
});
this.on("update", function() {
  ih.last_change = ih.getLastModeChange();
  ih.modes = uR.db.ih.Mode.objects.all().sort(function(m1,m2) {
    if (m1.name > m2.name) { return 1 }
    return (m2.name>m1.name)?-1:0;
  })
})
setMode(e) {
  this.ajax({
    url: "/api/schema/ih.ModeChangeForm/",
    method: "POST",
    data: { mode: e.item.mode.id, created: moment().format("YYYY-MM-DD HH:mm") },
    success: function(data) {
      new uR.db.ih.ModeChange({values_list: data.values_list});
      this.update();
    },
  });
}
  </script>
</mode-viewer>