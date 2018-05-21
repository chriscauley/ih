uR.router.default_route = uR.router.routeElement("task-list");
uR.router.add({
  "^/$": uR.router.default_route,
});
ih.ready(function() { uR.router.start() });