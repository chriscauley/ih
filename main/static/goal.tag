/*class Task extends uR.db.DataModel {
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
  getDisplayItems(edit_mode) {
    var goals = _.sortBy(this.goal_set(),'targeted');
    var next = this.getNotCompleted(goals);
    var last = _.sortBy(goals,"completed").filter((g) => g.completed).pop();
    var time_delta = this.getTimeDelta(goals,next,last);
    var items = [];
    if (next && next.started) { return items; }

    if (edit_mode) { // show next and last with edit buttons
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
    if (this.isTimer()) {
      field = goal.started?'completed':'started';
    }
    goal[field] = data[field] = now;
    riot_tag.ajax({
      url: "/api/schema/ih.GoalForm/"+goal.id+"/",
      method: "POST",
      data: data,
      success: function(data) {
        var goal = new Goal({ values_list: data.values_list });
        goal.task.cache_delta = "undefined";
      },
    });
  };
}
*/
class Goal extends uR.db.DataModel {
  constructor(opts={}) {
    opts._is_api = true;
    super(opts);
  }
  __str() {
    var time_string = this.completed?"DONE: "+this.completed.hdatetime():"t"+this.targeted.htimedelta();
    return `${this.task.name} ${time_string}`
  }
  createDataFields() {
    super.createDataFields();
    var task = this.schema.get("task").value;
    task = task && uR.db.ih.Task.objects.get(task);
    if (!task) { return }
    var checklist = task.checklist && task.checklist.split(",") || [];
    uR.forEach(checklist,function (check_name) {
      this.data_fields.push({ label: check_name, type: "boolean", required: false });
    },this);
    if (task.lap_timers) {
      var start = () => this.started && this.started.unixtime();
      var choices = task.lap_timers.split(",")
      this.data_fields.push({ label: "Lap", type: "lap-timer", required: false, choices: choices, start: start })
    }
    var metrics = task.metrics;
    if (metrics) {
      metrics.indexOf('count') != -1 && this.data_fields.push({ name: "count", type: "integer" });
      metrics.indexOf('distance') != -1 && this.data_fields.push({ name: "distance", type: "number" });
      metrics.indexOf('weight') != -1 && this.data_fields.push({ name: "weight", type: "number" });
    }
  }
  isTimer() {
    return this.task.metrics.indexOf("timer") != -1;
  }
  update() {
    if (ih.edit_mode) { this.action_icon = "edit"; }
    else { this.action_icon = this.isTimer()?"clock-o":"check" }
  }
  getMiniSchema() {
    return this.started && this.data_fields;
  }
  saveMe(riot_tag,data={}) {
    _.extend(data,riot_tag.getData && riot_tag.getData() || {});
    for (var key in data) { this[key] = data[key]; }
    riot_tag.ajax({
      url: "/api/schema/ih.GoalForm/"+this.id+"/",
      method: "POST",
      data: {task: this.task.id, data: this.toJson().data},
      success(data) {
        var goal = new Goal({ values_list: data.values_list });
        goal.task.cache_delta = "undefined";
      },
    });
  }
}

uR.db.register("ih",[Goal]);