window.ih = {}
uR.config.form_prefix = "#";
uR.ready(function() {
  var done = 0;
  var results = {};
  var models = [];
  ih.tasks = [];
  ih.taskcompletions = [];
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
          uR.db.schema[model_name] = data.schema;
          ih[model_name.toLowerCase()+"s"] = data.ur_pagination.results.map((r) => new uR.db.ih[model_name]({
            values_list: r,
          }));
        });
      }
    });
  }
  loadModel('TaskGroup');
  loadModel('Task');
  loadModel('TaskCompletion');
  uR.config.name_overrides.completed = { type: "datetime-local" };
});