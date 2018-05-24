uR.db.ModelManager = uR.db.MapModelManager;
class TaskGroup extends uR.db.Model {
  constructor(opts={}) {
    super(opts);
  }
  __str() {
    return this.name;
  }
}

var FIRST_TIMES = {
  "Arm Curls": 9,
  "Beer": 19,
  "Eat": 10,
  "Smoke Cigarette": 11,
}

var MINUTES_BETWEEN = {
  "Arm Curls": 3,
  "Beer": 90,
  "Eat": 6*60,
  "Smoke Cigarette": 180,
}

class Task extends uR.db.DataModel {
  constructor(opts={}) {
    super(opts);
  }
  __str() {
    return this.name;
  }
  createSchema() {
    this.data_fields = [
      { name: "task_type", choices: ["",'counter','timer'], type: "select", required: false },
    ];
    super.createSchema();
  }
  getIcon() {
    if (this.task_type == "timer") { return "clock-o"; }
    return "check";
  }
  getIntervalDisplay() {
    if (!isNaN(this.interval)) { return `every ${this.interval} days` }
    return uR.unslugify(this.interval || "");
  }
  getNotCompleted(goals) {
    // the goal_set lookup is slow right now, so we can pass in goals to avoid another round of parsing.
    return (goals || this.goal_set()).filter((g) => !g.completed)[0];
  }
  adminPostRender() {
    var options = {
      parent: document.querySelector("ur-form .post-form"),
    }
    var riot_options = {
      results: this.goal_set().map(function(goal) {
        return { url: goal.getAdminUrl(), fields: [goal.targeted.hdatetime(),goal.completed && goal.completed.hdatetime()] };
      }),
    }
    uR.newElement("ur-pagination",options,riot_options);
  }
  getTimeDelta() {
    if (this.cache_delta && (this.expire > new Date())) { return this.cache_delta }
    if (!this.goal_set) { return }

    // There should only be one incomplete goalfor any task, if not create it
    var goals = _.sortBy(this.goal_set(),'targeted');
    var next = this.getNotCompleted(goals);
    var now = nextimate = moment();
    var today = now.format("YYYY-MM-DD");
    var yesterday = now.clone().add(-1,"days").format("YYYY-MM-DD");;
    var week_ago = now.clone().add(-7,"days").format("YYYY-MM-DD");;
    var _completed = (g) => g.completed && g.completed.moment().format("YYYY-MM-DD");
    var times_today = goals.filter((g) => _completed(g) == today).length;
    var times_yesterday = goals.filter((g) => _completed(g) == yesterday).length;
    var times_week_ago = goals.filter((g) => _completed(g) <= week_ago).length;
    var last = goals[goals.length-1]; // last goal is most recent
    if (!next) {
      // TODO: this._calculating is hacky. Figure out why this is being called twice
      if (this._calculating) { "Calculating... (please refresh)"; }
      if (last) { // previous completion exists
        var nextimate = moment(last.completed);
        if (this.per_time != 1) { // things that should be done more than once on target day
          if (today == nextimate.format("YYYY-MM-DD")) { // goal completed today
            nextimate = nextimate.add((MINUTES_BETWEEN[this.name] || 180),'minutes');
            if (today != nextimate.format("YYYY-MM-DD") // nextimate is tomorrow
                || times_today >= this.per_time) { // or task completed enough today
              // so move into future however many intervals it should be
              nextimate = moment().startOf("day").add(this.interval,"days").set("hour",FIRST_TIMES[this.name] || 0);
            }
          } else { // no goal completed today
            nextimate = moment().startOf("day").set("hour",FIRST_TIMES[this.name] || 0);
          }
        }
        else if (this.interval == "monthly") {
          nextimate.add(1,'months');
        } else if (this.interval == "every_two_months") {
          nextimate.add(2,'months');
        } else {
          nextimate.add(this.interval,"days")
        }
      }
      uR.ajax({
        url: "/api/schema/ih.GoalForm/",
        method: "POST",
        data: { task: this.id, targeted: nextimate.format("YYYY-MM-DD HH:mm") },
        success: function(data) {
          var goal = new Goal({ values_list: data.values_list });
          ih.goals.push(goal);
          goal.task.cache_delta = undefined;
          uR.router._current_tag.update()
        }.bind(this),
      });
      this._calculating = true;
      return "Calculating... (please refresh)";
    }
    this._calculating = false;
    this.cache_delta = "";
    if (this.alignment =="neutral") {
      var last = goals.filter(g => g.completed ).pop();
      this.last_time = last && last.completed.unixtime();
    } else {
      this.target_time = next.targeted.unixtime();
    }
    if (times_today) { this.cache_delta += " Tx"+times_today }
    if (times_yesterday) { this.cache_delta += " Yx"+times_yesterday }
    if (times_week_ago) { this.cache_delta += " Wx"+times_week_ago }

    var expiry_time = 1000;
    if (this.cache_delta.indexOf("h") != -1) { expiry_time = 60*60*1000 }
    if (this.cache_delta.indexOf("m") != -1) { expiry_time = 60*1000 }
    this.expire = new Date().valueOf() + expiry_time;
    return this.cache_delta;
  }
  click(e,riot_tag) {
    riot_tag.ajax({
      url: "/api/schema/ih.GoalForm/"+this.getNotCompleted().id+"/",
      method: "POST",
      data: { task: this.id, completed: moment().format("YYYY-MM-DD HH:mm:ss") },
      success: function(data) {
        var goal = new Goal({ values_list: data.values_list });
        ih.goals.push(goal);
        uR.forEach(ih.tasks,function (task) { if (task.id == goal.task.id) { task.cache_delta = undefined } })
      },
    });
  };
}
class Goal extends uR.db.DataModel {
  constructor(opts={}) {
    super(opts);
  }
  __str() {
    var time_string = this.completed?"DONE: "+this.completed.hdatetime():"t"+this.targeted.htimedelta();
    return `${this.task.name} ${time_string}`
  }
}

uR.db.register("ih",[Task,Goal,TaskGroup]);

<task-list>
  <div class="scroll-list active top container" ur-mode={ edit_mode?"edit":"add" }>
    <div class="columns">
      <div class="column col-4 hide-inactive">
        <div class="card">
          <a class="card-body card-body-sm" href={ uR.db.ih.Task.admin_new_url }>
            <i class="btn-sm { uR.css.btn.primary } { uR.icon('plus') } { uR.css.right }"></i>
            Task
          </a>
        </div>
      </div>
      <div class="column col-4 hide-inactive">
        <div class="card">
          <a class="card-body card-body-sm" href={ uR.db.ih.TaskGroup.admin_new_url }>
            <i class="btn-sm { uR.css.btn.primary } { uR.icon('plus') } { uR.css.right }"></i>
            Group
          </a>
        </div>
      </div>
      <div class="column col-4 hide-inactive">
        <div class="card">
          <div class="card-body card-body-sm pointer" onclick={ toggleEdit }>
            <!-- <span>{ edit_mode?'Edit':'Add' } Mode</span> -->
            <div style="display:flex;">
              <i class="btn-sm { uR.css.btn[edit_mode?'default':'primary'] } { uR.icon("check") } { uR.css.right }"></i>
              <i class="btn-sm { uR.css.btn[edit_mode?'primary':'default'] } { uR.icon("edit") } { uR.css.right }"></i>
            </div>
          </div>
        </div>
      </div>
      <div class="column col-6" each={ task, i in ih.tasks }>
        <div class="card">
          <div class="card-body">
            <button class="btn btn-primary float-right { uR.icon(task.icon) }"
                    onclick={ clickTask }></button>
            <div>
              <div>{ task }</div>
              <div class="time-delta">{ task.getTimeDelta() }</div>
              <span if={ task.last_time } data-target_time={ task.last_time }>Last: </span>
              <span if={ task.target_time } data-target_time={ task.target_time }></span>
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
  var edit_mode = this.edit_mode;
  ih.tasks = _.chain(ih.tasks).each(function(task) {
    task.getTimeDelta();
    task.icon = edit_mode?"edit":task.getIcon();
  }).sortBy("last_time").sortBy("target_time").value();
})
route() { }
clickTask(e) {
  var id = e.item.task.id;
  if (this.edit_mode) { return e.item.task.edit(); }
  e.item.task.click(e,this);
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
  if (this.edit_mode) { return goal.edit() }
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