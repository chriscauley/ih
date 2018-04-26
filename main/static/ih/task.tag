class Task extends uR.db.Model {
  constructor(opts={}) {
    uR.defaults(opts,{ // this should be moved into a class that gets its structure remotely
      schema: uR.db.schema.Task, // from json schema object
    });
    if (opts.values_list) {
      var id,_values;
      [id,..._values] = opts.values_list;
      for (var i in opts.schema) {
        opts.schema[i].value = _values[i];
      }
    }
    super(opts)
    if (opts.values_list) {
      var manager = this.constructor.objects;
      this.pk = this[this.META.pk_field] = id;
      if (manager._getPKs().indexOf(this.pk) == -1) {
        manager._addPK(this.pk);
        console.log("saving",id);
        this.save();
      }
    }
  }
  __str() {
    return `"${this.name}" ${this.per_time} time(s) ${this.getFrequencyDisplay()} `
  }
  getFrequencyDisplay() {
    if (!isNaN(this.frequency)) { return `every ${this.frequency} days` }
    return uR.unslugify(this.frequency);
  }
}

uR.db.register("task",[Task]);

<task-list>
  <a href="#/new/Task/" class="{ uR.css.btn.primary } { uR.icon('plus') }"></a>
  <div each={ task, i in tasks }>{ task }
  </div>

  <script>
this.on("before-mount", function() { // #! TODO: move to uR.AjaxMixin
    this.page = {results: []};
})
this.on("mount",function() {
  this.ajax({ url: "/api/schema/ih.TaskForm/", data: { ur_page: 1 } })
});
route() { }
ajax_success(data) {
  if (data.ur_pagination) {
    this.page = data.ur_pagination; // #! TODO: move to uR.AjaxMixin
    uR.db.schema = uR.db.schema || {};
    uR.db.schema.Task = data.schema;
    window.tasks = this.tasks = this.page.results.map((r) => new Task({
      values_list: r
    }));
  }
}
  </script>
</task-list>