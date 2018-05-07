class Task extends uR.db.Model {
  __str() {
    var p = (this.per_time ==1)?"once":`${this.per_time} times`;
    return `"${this.name}" ${p} ${this.getIntervalDisplay()} `
  }
  getIntervalDisplay() {
    if (!isNaN(this.interval)) { return `every ${this.interval} days` }
    return uR.unslugify(this.interval || "");
  }
  getTimeDelta() {
    if (!this.taskcompletion_set) { return }
    var last = this.taskcompletion_set().pop();
    if (!last) { return "Never" }
    return last.completed.htimedelta();
  }
}
class TaskCompletion extends uR.db.Model {
  __str() {
    return `${this.task.name} ${this.completed.hdatetime()}`;
  }
}

uR.db.register("ih",[Task,TaskCompletion]);

<task-list>
  <div class="scroll-list active top container">
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
            <div>
              <div>{ task }</div>
              <div class="time-delta">{ task.getTimeDelta() }</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <task-completion-list class="scroll-list bottom inactive container"></task-completion-list>

  <script>
this.on("before-mount", function() { // #! TODO: move to uR.AjaxMixin
    this.page = {results: []};
})
this.on("mount",function() {
  this.ajax({ url: "/api/schema/ih.TaskForm/", data: { ur_page: 1 } })
});
this.on("update",function() {
  // this presents a memory leak since it continuously makes new date strings and stores them in the lunch cache
  // investigate before uncommenting
  /*var minutes,seconds;
  uR.forEach(this.root.querySelectorAll(".time-delta"),function(e) {
    seconds = seconds || e.innerText.indexOf("second");
    minutes = minutes || e.innerText.indexOf("minute");
  });
  var t;
  if (seconds) { t= 1000; }
  else if (minutes) { t = 60*1000; }
  else { t = 10*60*1000; String.lunch.clear(); } //clear wipes the cache, which is a sort of memory leak
  setTimeout(() => this.update(),t);*/
})
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
  <div class="columns">
    <div class="column col-12">
      <div class="card" each={ tc,i in task_completions }>
        <div class="card-body">
          <div>{ tc.task.name }</div>
          <div>{ tc.completed.hdatetime() }</div>
        </div>
      </div>
    </div>
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
    this.parent.update();
  }
}
  </script>
</task-completion-list>