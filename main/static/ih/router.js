uR.router.default_route = uR.router.routeElement("task-list");
uR.router.add({
  "#/new/([^/]+)/": function(pathname,data) {
    uR.mountElement("ur-form",{
      schema: "/api/schema/ih."+data.matches[1]+"Form/",
      method: "POST",
      ajax_success: function() { uR.route("/") }
    });
  },
  "^/$": uR.router.default_route,
});


uR.ready(function() { uR.router.start() });