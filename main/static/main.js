uR.auth_enabled = true;
uR.db.ModelManager = uR.db.MapModelManager;
window.ih = {
  ready: uR.Ready(),
  refreshData: function() {
    if (!uR.auth.user) { return uR.router.start(); }
    var done = 0;
    var results = {};
    function loadModels(models) {
      var models = ["TaskGroup","Task","Goal","Mode","ModeChange"].map(n => ({model_key: "ih."+n}))
      // #! TODO: because the .tag files aren't loaded yest this doesn't work
      // the following can be uncommented and the above deleted once the tag files are compiled server side
      // models = models || uR.db.ih._models;
      function success(data) {
        done++;
        results[data.ur_model] = data;
        if (done != models.length) { return; }
        uR.forEach(models,function(model) {
          var data = results[model.model_key.toLowerCase()];
          uR.db.schema[model.model_key] = data.schema;
          data.ur_pagination.results.map((r) => new uR.db[model.model_key]({
            values_list: r,
          }));
          // #! TODO: fix the following
          // necessary to create related lookup ala uR.db.ForeignKey if pagination is empty
          new uR.db[model.model_key]();
        });
        ih.ready.start();
      }
      for (var model of models) {
        uR.ajax({
          url: "/api/schema/"+model.model_key+"Form/?ur_page=0&",
          success: success,
        });
      }
    }
    loadModels();
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