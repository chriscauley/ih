class TaskGroup extends uR.db.Model {
  constructor(opts={}) {
    super(opts);
  }
  __str() {
    return this.name;
  }
}

class Task extends uR.db.Model {
  constructor(opts={}) {
    super(opts);
  }
  __str() {
    return this.name;
  }
  getIntervalDisplay() {
    if (!isNaN(this.interval)) { return `every ${this.interval} days` }
    return uR.unslugify(this.interval || "");
  }
  getTimeDelta() {
    if (this.cache_delta && (this.expire > new Date())) { return this.cache_delta }
    if (!this.goal_set) { return }
    var last = this.goal_set().pop();
    if (!last) { return "Never" }
    this.cache_delta = last.completed.htimedelta();
    var expiry_time = 1000;
    if (this.cache_delta.indexOf("h") != -1) { expiry_time = 60*60*1000 }
    if (this.cache_delta.indexOf("m") != -1) { expiry_time = 60*1000 }
    this.expire = new Date().valueOf() + expiry_time;
    return this.cache_delta;
  }
}
class Goal extends uR.db.Model {
  constructor(opts={}) {
    super(opts);
  }
  __str() {
    return `${this.task.name} ${this.completed.hdatetime()}`;
  }
}

uR.db.register("ih",[Task,Goal,TaskGroup]);

<task-list>
  <div class="scroll-list active top container" ur-mode={ edit_mode?"edit":"add" }>
    <div class="columns">
      <div class="column col-4 hide-inactive">
        <div class="card">
          <a class="card-body card-body-sm" href="#/new/Task/">
            <i class="btn-sm { uR.css.btn.primary } { uR.icon('plus') } { uR.css.right }"></i>
            Task
          </a>
        </div>
      </div>
      <div class="column col-4 hide-inactive">
        <div class="card">
          <a class="card-body card-body-sm" href="#/new/TaskGroup/">
            <i class="btn-sm { uR.css.btn.primary } { uR.icon('plus') } { uR.css.right }"></i>
            Group
          </a>
        </div>
      </div>
      <div class="column col-4 hide-inactive">
        <div class="card">
          <div class="card-body card-body-sm pointer" onclick={ toggleEdit }>
            <!-- <span>{ edit_mode?'Edit':'Add' } Mode</span> -->
            <div class="btn-group btn-group-block">
              <i class="btn-sm { uR.css.btn[edit_mode?'default':'primary'] } { uR.icon("check") } { uR.css.right }"></i>
              <i class="btn-sm { uR.css.btn[edit_mode?'primary':'default'] } { uR.icon("edit") } { uR.css.right }"></i>
            </div>
          </div>
        </div>
      </div>
      <div class="column col-6" each={ task, i in ih.tasks }>
        <div class="card">
          <div class="card-body">
            <button class="btn btn-primary float-right { uR.icon(edit_mode?'edit':'check') }" onclick={ markComplete }></button>
            <div>
              <div>{ task }</div>
              <div class="time-delta">{ task.getTimeDelta() }</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="scroll-list-trigger" onclick={ switchActive }></div>
  <task-completion-list class="scroll-list bottom inactive container"></task-completion-list>

  <script>
this.on("before-mount", function() { // #! TODO: move to uR.AjaxMixin
    this.page = {results: []};
})
this.on("mount",function() {
var self = this;
setTimeout(function() { self.update() },1000)
});
toggleEdit(e) {
  this.edit_mode = !this.edit_mode;
}
switchActive(e) {
  uR.forEach(this.root.querySelectorAll(".scroll-list"),(e) => e.classList.toggle("inactive"));
}
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
markComplete(e) {
  var id = e.item.task.id;
  if (this.edit_mode) { return uR.route("#/edit/Task/"+id+"/"); }
  this.ajax({
    url: "/api/schema/ih.GoalForm/",
    method: "POST",
    data: { task: id, completed: moment().format("YYYY-MM-DD HH:mm:ss") },
    success: function(data) {
      var goal = new Goal({ values_list: data.values_list });
      ih.goals.push(goal);
      uR.forEach(ih.tasks,function (task) { if (task.id == goal.task.id) { task.cache_delta = undefined } })
    },
  });
}
  </script>
</task-list>

<task-completion-list>
  <div class="columns">
    <div class="column col-12">
      <div class="card bg-secondary" each={ goal,i in ih.goals } ur-id={ goal.id }>
        <div onclick={ undelete } class="card-body undo-delete bg-error" if={ goal.deleted }>
          Undo <i class="fa fa-undo float-right"></i>
        </div>
        <div class="card-body">
          <button class="{ uR.css.btn.cancel } float-right { uR.icon(edit_mode?'edit':'trash') }"
                  onclick={ delete }></button>
          <div>
            <div>{ goal.task.name }</div>
            <div>{ goal.completed.hdatetime() }</div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <script>
this.on("update",function() {
  this.edit_mode = this.parent.edit_mode;
  if (this.root.classList.contains("inactive")) {
    var e = this.root;
    setTimeout(() => e.scroll(0,e.scrollHeight), 100);
  }
});
delete(e) {
  var goal = e.item.goal;
  if (this.edit_mode) { return uR.route("#/edit/Goal/"+goal.id+"/"); }
  this.ajax({
    method:  "DELETE",
    url: "/api/schema/ih.GoalForm/"+goal.id+"/",
    success: () => { goal.deleted = true; },
    target: this.root.querySelector(`[ur-id="${goal.id}"]`),
  });
}
undelete(e) {
  var goal = e.item.goal;
  this.ajax({
    method:  "DELETE",
    url: "/api/schema/ih.GoalForm/"+goal.id+"/?undo",
    success: () => { goal.deleted = false; },
    target: this.root.querySelector(`[ur-id="${goal.id}"]`),
  });
}
  </script>
</task-completion-list>