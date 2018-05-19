uR.router.default_route = uR.router.routeElement("task-list");
uR.router.add({
  "#/new/([^/]+)/": function(pathname,data) {
    uR.mountElement("ur-form",{
      schema: "/api/schema/ih."+data.matches[1]+"Form/",
      method: "POST",
      ajax_success: () => uR.route("/"),
      cancel_function: () => uR.route("/"),
    });
  },
  "#/edit/([^/]+)/(\\d+)/": function(pathname,data) {
    var model_name = data.matches[1];
    var pk = data.matches[2];
    var post_render;
    if (model_name == "Task") {
      function post_render() {
        uR.pagination == undefined;
        var goals = uR.db.ih.Goal.objects.filter({task:pk});
        var results = goals.map(function(goal) {
          return {
            url: "#/edit/Goal/"+goal.pk+"/",
            fields: [goal.targeted,goal.completed],
          }
        });
        uR.pagination = {
          results: results,
        };
      }
    }
    uR.mountElement("ur-form",{
      schema: `/api/schema/ih.${model_name}Form/${pk}/`,
      method: "POST",
      ajax_success: () => uR.route("/"),
      cancel_function: () => uR.route("/"),
      post_render: post_render,
    });
  },
  "^/$": uR.router.default_route,
});


uR.ready(function() { uR.router.start() });