class RemoteModel extends uR.db.Model {
  constructor(opts={}) {
    uR.defaults(opts,{ // this should be moved into a class that gets its structure remotely
      // should get schema from uR.db.schema
    });
    if (opts.values_list) {
      var [id,..._values] = opts.values_list;
      for (var i in opts.schema) {
        opts.schema[i].value = _values[i];
      }
    }
    super(opts);
    if (opts.values_list) {
      var manager = this.constructor.objects;
      this.pk = this[this.META.pk_field] = id;
      if (manager._getPKs().indexOf(this.pk) == -1) {
        manager._addPK(this.pk);
        this.save();
      }
    }
  }
  __str() {
    var p = (this.per_time ==1)?"once":`${this.per_time} times`;
    return `"${this.name}" ${p} ${this.getFrequencyDisplay()} `
  }
  getFrequencyDisplay() {
    if (!isNaN(this.frequency)) { return `every ${this.frequency} days` }
    return uR.unslugify(this.frequency);
  }
}

class Task extends RemoteModel {
  constructor(opts={}) {
    opts.schema = opts.schema || uR.db.schema.Task;
    super(opts);
  }
}
class TaskCompletion extends RemoteModel {
  constructor(opts={}) {
    opts.schema = opts.schema || uR.db.schema.TaskCompletion;
    super(opts);
  }
}


uR.db.register("ih",[Task,TaskCompletion]);

<task-list>
  <div class="container">
    <div class="columns">
      <div class="column col-12">
        <div class="card">
          <a class="card-body" href="#/new/Task/">
            Add new Task
            <i class="{ uR.css.btn.primary } { uR.icon('plus') } { uR.css.right }"></i>
          </a>
        </div>
        <div class="card" each={ task, i in tasks }>
          <div class="card-body">
            <button class="btn btn-primary float-right { uR.icon('check') }" onclick={ markComplete }></button>
            { task }
          </div>
        </div>
      </div>
    </div>
  </div>

  <task-completion-list></task-completion-list>

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
      values_list: r,
      schema: data.schema,
    }));
  }
}
markComplete(e) {
  this.ajax({
    url: "/api/schema/ih.TaskCompletionForm/",
    method: "POST",
    data: { task: e.item.task.id, completed: moment().format("YYYY-MM-DD HH:mm:ss") }
  })
}
  </script>
</task-list>

<task-completion-list>
  <div each={ tc,i in task_completions }>
    { tc.id }
  </div>

  <script>
this.on("mount",function() {
  this.ajax({ url: "/api/schema/ih.TaskCompletionForm/", data: { ur_page: 1 } })
});
ajax_success(data) {
  if (data.ur_pagination && data.ur_model) {
    this.page = data.ur_pagination; // #! TODO: move to uR.AjaxMixin
    uR.db.schema = uR.db.schema || {};
    uR.db.schema.TaskCompletion = data.schema;
    this.task_completions = this.page.results.map((r) => new TaskCompletion({
      values_list: r,
      schema: data.schema,
    }));
  }
}
  </script>
</task-completion-list>