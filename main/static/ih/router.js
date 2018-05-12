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
    uR.mountElement("ur-form",{
      schema: `/api/schema/ih.${model_name}Form/${pk}/`,
      method: "POST",
      ajax_success: () => uR.route("/"),
      cancel_function: () => uR.route("/"),
    });
  },
  "^/$": uR.router.default_route,
});


uR.ready(function() { uR.router.start() });