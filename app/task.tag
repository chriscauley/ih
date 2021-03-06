class TaskGroup extends uR.db.Model {
  constructor(opts={}) {
    opts._is_api = true;
    super(opts);
  }
  __str() {
    return this.name;
  }
}

ih.FIRST_HOURS = {
  "Arm Curls": 9,
  "Beer": 19,
  "Eat": 10,
  "Smoke Cigarette": 11,
}

ih.MINUTES_BETWEEN = {
  "Arm Curls": 3,
  "Beer": 90,
  "Eat": 6*60,
  "Smoke Cigarette": 180,
}

class Task extends uR.db.DataModel {
  constructor(opts={}) {
    opts._is_api = true;
    super(opts);
  }
  __str() {
    return this.name;
  }
  createDataFields() {
    var METRIC_CHOICES = ["count","timer","distance","weight"];
    this.data_fields = [
      { name: "trigger-mode", help_text: "Automatically switch to this mode when this task is triggered",
        type: "select", choices: () => [undefined].concat(Mode.objects.all().map(m=>[m.id,m.name])),
        required: false },
      { name: "metrics", choices: METRIC_CHOICES, type: "checkbox", required: false },
      { name: "lap_timers", required: false, help_text: "Comma separated items to denote the start of each lap" },
      { name: "checklist", help_text: "Comma separated items to check off every time you do the task",
        required: false },
    ];
  }
  getClassName(riot_tag) {
    return `column task_${uR.slugify(this.name)} col-6`
  }
  getIntervalDisplay() {
    if (!isNaN(this.interval)) { return `every ${this.interval} days` }
    return uR.unslugify(this.interval || "");
  }
  getGoal() {
    return this.getNotCompleted();
  }
  getNotCompleted(goals) {
    // the goal_set lookup is slow right now, so we can pass in goals to avoid another round of parsing.
    return this.id && (goals || this.goal_set()).filter((g) => !g.completed)[0];
  }
  adminPostRender() {
    var options = {
      parent: document.querySelector("ur-form .post-form"),
    }
    var riot_options = {
      results: this.id && this.goal_set().map(function(goal) {
        return {
          url: goal.getAdminUrl(),
          delete: () => alert("not implemented!"),
          fields: [
            goal.completed && ("Last: "+goal.completed.hdatetime()) || goal.targeted.hdatetime(),
          ]
        };
      }),
    }
    uR.newElement("ur-pagination",options,riot_options);
  }
  getDisplayItems() {
    var goals = _.sortBy(this.goal_set(),'targeted');
    var next = this.getNotCompleted(goals);
    var last = _.sortBy(goals,"completed").filter((g) => g.completed).pop();
    var time_delta = this.getTimeDelta(goals,next,last);
    var items = [];
    if (next && next.started) { return items; }

    if (ih.ui_mode == "edit") { // show next and last with edit buttons
      var _i = uR.icon('edit');
      last && items.push({ icon: _i, click: (e) => last.edit(), target_time: last.completed.unixtime(),
                           text: "Last: "});
      next && items.push({ icon: _i, click: (e) => next.edit(), target_time: next.targeted.unixtime(),
                           text: "Next: "});
    } else { // show next || last || nothing
      next && items.push({ target_time: next.targeted.unixtime() });
      !next && last && items.push({ text: "Last: ", target_time: last.completed.unixtime() });
    }
    // in either mode, show the weeks/months, etc
    items.push({ text: time_delta, className: "time-delta" });
    return items;
  }
  getTimeDelta(goals,next,last) {
    if (this._cache_delta) { return this._cache_delta }
    // There should only be one incomplete goal for any task, if not create it
    this.started = next && next.started && next.started.unixtime();
    var now = nextimate = moment();
    var today = now.format("YYYY-MM-DD");
    var yesterday = now.clone().add(-1,"days").format("YYYY-MM-DD");;
    var week_ago = now.clone().add(-7,"days").format("YYYY-MM-DD");;
    var _completed = (g) => g.completed && g.completed.moment().format("YYYY-MM-DD");
    var times_today = goals.filter((g) => _completed(g) == today).length;
    var times_yesterday = goals.filter((g) => _completed(g) == yesterday).length;
    var times_week_ago = goals.filter((g) => _completed(g) <= week_ago).length;
    var data = {};
    if (!next) {
      // TODO: this._calculating is hacky. Figure out why this is being called twice
      if (this._calculating) { return "Calculating... (please refresh)"; }
      if (last) { // previous completion exists
        var nextimate = moment(last.completed);
        var first_hour = ih.FIRST_HOURS[this.name] || 0;
        if (this.per_time != 1) { // things that should be done more than once on target day
          if (today == nextimate.format("YYYY-MM-DD")) { // goal completed today
            nextimate = nextimate.add(ih.MINUTES_BETWEEN[this.name] || 180,'minutes');
            if (today != nextimate.format("YYYY-MM-DD") // nextimate is tomorrow
                || times_today >= this.per_time) { // or task completed enough today
              // so move into future however many intervals it should be
              nextimate = moment().startOf("day").add(this.interval,"days").set("hour",first_hour);
            }
          } else { // no goal completed today
            nextimate = moment().startOf("day").set("hour",first_hour);
          }
        }
        else if (this.interval == "monthly") {
          nextimate.add(1,'months');
        } else if (this.interval == "every_two_months") {
          nextimate.add(2,'months');
        } else {
          nextimate.add(this.interval,"days")
        }
        if (last.weight) { data.weight = last.weight }
        if (last.count) { data.count = last.count }
        if (last.distance) { data.distance = last.distance }
      } else {
        nextimate = moment();
      }
      this.makeNewGoal(nextimate.format("YYYY-MM-DD HH:mm"),data);
      return "Calculating... (please refresh)";
    }
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
  makeNewGoal(targeted,data) {
    var self = this;
    uR.ajax({
      url: "/api/schema/ih.GoalForm/",
      method: "POST",
      data: { task: this.id, targeted: targeted, data: data },
      success: function(data) {
        var goal = new Goal({ values_list: data.values_list });
        goal.task.cache_delta = undefined;
        uR.router._current_tag.update()
        self._calculating = false;
      },
    });
    this._calculating = true;
  }
  click(e,riot_tag) {
    var goal = this.getNotCompleted();
    var data = { task: this.id };
    var now = moment().format("YYYY-MM-DD HH:mm:ss");
    var field = "completed";
    field = goal.started?'completed':'started';
    data[field] = now;
    goal.saveMe(riot_tag,data)
    if (field == 'started' && goal.task['trigger-mode']) {
      new ModeChange({mode: goal.task['trigger-mode']}).saveAjax(riot_tag);
    }
  }
}

uR.db.register("ih",[Task,TaskGroup]);

<task-card class={ task.getClassName(this) }>
  <div class="card card-body">
    <div class="task-name">{ task.name }</div>
    <div class="flexy">
      <div each={ item,i in task.getDisplayItems() } onclick={ item.click }
           class="{ 'pointer block': item.click }">
        <i if={ item.click } class={ item.icon }></i>
        { item.text }
        <span if={ item.target_time } data-target_time={ item.target_time }></span>
      </div>
    </div>
    <button class="btn btn-sm btn-primary top-right" onclick={ clickTask }>
      <i class={ uR.icon(goal.action_icon) }></i>
      <span if={ goal.started } data-target_time={ goal.started.unixtime() }></span>
    </button>
    <div data-is={ form.data_is } opts={ form }></div>
  </div>

  <script>
  this.form = {};
  this.goal = {};
clickTask(e) {
  var id = e.item.task.id;
  if (ih.ui_mode == "edit") { return e.item.task.edit(); }
  e.item.task.click(e,this);
}
getTaskCard() {
  var goal = this.task.getNotCompleted();
  if (goal && goal.started && goal.data_fields && goal.data_fields.length) { return "ur-form" }
}
this.on("mount", function() { this.update() });
this.on("update", function() {
  this.form = {};
  var goal = this.goal = this.task.getNotCompleted();
  if (!goal) { this.goal = {}; return }
  goal.update();
  if (goal.started && goal.data_fields && goal.data_fields.length) {
    this.form = {
      "data_is": "ur-form",
      schema: goal.getMiniSchema(),
      autosubmit: true,
      theme: { outer: 'mini-form' },
      submit: (riot_tag) => goal.saveMe(riot_tag),
    }
  }
})
  </script>
</task-card>
<task-list>
  <div class="container" ur-mode={ ih.ui_mode }>
    <div class="flexy">
      <a href="/" class="card card-body card-body-sm" data-badge={ active_timers.length || "" }>
        <i class="fa-2x { uR.icon('home') }"></i>
      </a>
      <a each={ group, i in taskgroups } href="/group/{group.id}/" class="card card-body card-body-sm">
        <i class="fa-2x { uR.icon(group.icon) }"></i>
      </a>
    </div>
    <div class="columns">
      <task-card each={ task, i in tasks }></task-card>
    </div>
  </div>
  <div class="container bottom-bar">
    <mode-widget></mode-widget>
    <a class="btn-sm { uR.css.btn.primary }" href={ uR.db.ih.Task.admin_new_url }>
      <i class="{ uR.icon('plus') }"></i>
      Task
    </a>
    <a class="btn-sm { uR.css.btn.primary }" href={ uR.db.ih.TaskGroup.admin_new_url }>
      <i class="{ uR.icon('plus') }"></i>
      Group
    </a>
    <div class="btn-group" onclick={ toggleEdit }>
      <i each={ b in buttons } class="btn-sm { b.className } { uR.icon(b.icon) } { uR.css.right }"></i>
    </div>
  </div>
  <script>
this.mixin(uR.LunchTimeMixin)
this.on("before-mount", function() { // #! TODO: move to uR.AjaxMixin
  this.page = {results: []};
  this.active_timers = [];
})
this.on("mount",function() {
  var self = this;
  setTimeout(function() { self.update() },1000)
});
toggleEdit(e) {
  if (!ih.ui_mode) { ih.ui_mode = "edit"; }
  else if (ih.ui_mode == "edit") { ih.ui_mode = "info"; }
  else { ih.ui_mode = undefined; }
}
this.on("update",function() {
  String.lunch.watchTimers();
  this.active_timers = uR.db.ih.Goal.objects.all().filter(g => g.started && !g.completed);
  var a2c = active => uR.css.btn[active?'primary':'default'];
  var inactive = uR.css.btn.default;
  this.buttons = [
    { icon: "check", className: a2c(!ih.ui_mode) },
    { icon: "edit", className: a2c(ih.ui_mode == "edit") },
    { icon: "info", className: a2c(ih.ui_mode == "info") },
  ];
});
this.on("route",function (new_opts={}) {
  _.extend(this.opts,new_opts);
  this.taskgroups = uR.db.ih.TaskGroup.objects.all();
  this.group = undefined;
  var group_id = this.opts.matches && this.opts.matches[1];
  if (group_id == "misc") {
    // eventually this will show ungrouped tasks
  } else if (group_id) {
    this.group = uR.db.ih.TaskGroup.objects.get(group_id);
    this.tasks = this.group.task_set()
  } else {
    this.tasks = uR.db.ih.Goal.objects.all().filter(g => g.started && ! g.completed).map(g => g.task);
    // this will be for misc for now
    var orphan_tasks = Task.objects.filter({group: undefined}).filter(t => this.tasks.indexOf(t) == -1)
    this.tasks = this.tasks.concat(orphan_tasks);
    // this.tasks = _.chain(ih.tasks).sortBy("last_time").sortBy("target_time").value();
  }
})
  </script>
</task-list>
