window.ih = {
  ready: uR.Ready(),
  refreshData: function() {
    if (!uR.auth.user) {
      return uR.router.start();
    }
    var done = 0;
    var results = {};
    var models = [];
    ih.tasks = [];
    ih.goals = [];
    ih.taskgroups = [];
    function loadModel(name) {
      models.push(name);
      uR.ajax({
        url: "/api/schema/ih."+name+"Form/?ur_page=0&",
        success: function(data) {
          done++;
          results[name] = data;
          if (done != 3) { return; }
          uR.forEach(models,function(model_name) {
            var data = results[model_name];
            uR.db.schema["ih."+model_name] = data.schema;
            ih[model_name.toLowerCase()+"s"] = data.ur_pagination.results.map((r) => new uR.db.ih[model_name]({
              values_list: r,
            }));
          });
          ih.ready.start();
        }
      });
    }
    loadModel('TaskGroup');
    loadModel('Task');
    loadModel('Goal');
  }
};
uR.config.form_prefix = "#";
uR.ready(function() {
  uR.config.name_overrides.completed = { type: "datetime-local" };
  uR.config.name_overrides.started = { type: "datetime-local" };
  uR.config.name_overrides.targeted = { type: "datetime-local" };

  String.lunch.hdate = "M/D 'YY";
  String.lunch.hdate_no_year = "M/D";
  String.lunch.htime_hour = "H:mm";
  String.lunch.at = "@";

  var tt_cache = {};
  var target_time_interval = setInterval(function() {
    var elements = document.querySelectorAll("[data-target_time]");
    var now = new Date().valueOf();
    // var count = 0 // #! TODO Revisit how frequently this is called... could become a performance issue
    uR.forEach(elements,function(e,i) {
      var target = e.dataset.target_time;
      if (tt_cache[target] && tt_cache[target] > now) { return }
      //count ++; // #! ibid
      delta_ms = now-target;
      var display = e.dataset.target_time_display = String.lunch.ms2hdelta(delta_ms)
      tt_cache[target] = now;
      if (delta_ms < 3600000) { return } // less than an hour needs immediate update
      tt_cache[target] += 60000; // update in a minute
    });
    //console.log(count) #! ibid
  },1000)
  ih.refreshData();
});