class Task extends uR.db.Model {
  __str() {
    var p = (this.per_time ==1)?"once":`${this.per_time} times`;
    return `"${this.name}" ${p} ${this.getFrequencyDisplay()} `
  }
  getFrequencyDisplay() {
    if (!isNaN(this.frequency)) { return `every ${this.frequency} days` }
    return uR.unslugify(this.frequency || "");
  }
}
class TaskCompletion extends uR.db.Model {
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
    uR.db.schema.Task = data.schema;
    window.tasks = this.tasks = this.page.results.map((r) => new Task({
      values_list: r,
    }));
  }
}
markComplete(e) {
  this.ajax({
    url: "/api/schema/ih.TaskCompletionForm/",
    method: "POST",
    data: { task: e.item.task.id, completed: moment().format("YYYY-MM-DD HH:mm:ss") },
    success: function() {
      this.tags['task-completion-list'].updateData();
    }
  })
}
  </script>
</task-list>

<task-completion-list>
  <div each={ tc,i in task_completions }>
    { tc.task.name }
  </div>

  <script>
this.on("mount",function() {
  this.updateData();
});
updateData() {
  this.ajax({ url: "/api/schema/ih.TaskCompletionForm/", data: { ur_page: 1 } })
}
ajax_success(data) {
  if (data.ur_pagination && data.ur_model) {
    this.page = data.ur_pagination; // #! TODO: move to uR.AjaxMixin
    uR.db.schema.TaskCompletion = data.schema;
    this.task_completions = this.page.results.map((r) => new TaskCompletion({
      values_list: r,
    }));
  }
}
  </script>
</task-completion-list>