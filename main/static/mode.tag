class Mode extends uR.db.Model {
  constructor(opts={}) {
    opts._is_api = true;
    super(opts);
  }
  __str() {
    return this.name;
  }
}

uR.db.register("ih",[Mode])

<mode-widget onclick={ openViewer } class="pointer">
  <div>DOOT!</div>

  <script>
openViewer(e) {
  uR.route(uR.db.ih.Mode.admin_new_url);
}
  </script>
</mode-widget>

<mode-viewer class={ className }>
  
</mode-viewer>