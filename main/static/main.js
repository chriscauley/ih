uR.auth_enabled = true;
uR.db.ModelManager = uR.db.MapModelManager;
window.ih = {
  ready: uR.Ready(),
  refreshData: function() {
    if (!uR.auth.user) { return uR.router.start(); }
    var done = 0;
    var results = {};
    var models = [];
    ih.tasks = [];
    ih.goals = [];
    ih.taskgroups = [];
    ih.modes = [];
    function loadModels(model_names) {
      function success(data) {
        done++;
        results[data.ur_model.split(".")[1]] = data;
        if (done != model_names.length) { return; }
        uR.forEach(model_names,function(model_name) {
          var data = results[model_name.toLowerCase()];
          uR.db.schema["ih."+model_name] = data.schema;
          ih[model_name.toLowerCase()+"s"] = data.ur_pagination.results.map((r) => new uR.db.ih[model_name]({
            values_list: r,
          }));
          // #! TODO: fix the following
          new uR.db.ih[model_name](); // necessary to create related lookup ala uR.db.ForeignKey
        });
        ih.ready.start();
      }
      for (var model_name of model_names) {
        uR.ajax({
          url: "/api/schema/ih."+model_name+"Form/?ur_page=0&",
          success: success,
        });
      }
    }
    loadModels(['TaskGroup','Task','Goal','Mode']);
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
  ih.refreshData();
});