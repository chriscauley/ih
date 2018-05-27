window.ih = {
  ready: uR.Ready(),
};
uR.config.form_prefix = "#";
uR.ready(function() {
  String.lunch.hdate = "M/D 'YY";
  String.lunch.hdate_no_year = "M/D";
  String.lunch.htime_hour = "H:mm";
  String.lunch.at = "@";
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
        localStorage.clear(); // #! TODO: local storage currently caches deleted items.
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
  uR.config.name_overrides.completed = { type: "datetime-local" };
  uR.config.name_overrides.started = { type: "datetime-local" };
  uR.config.name_overrides.targeted = { type: "datetime-local" };
  String.lunch.watchTimers();
});