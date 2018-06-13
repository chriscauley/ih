uR.router.default_route = uR.auth.loginRequired(uR.router.routeElement("task-list"));
uR.router.add({
  "^/$": uR.router.default_route,
  "^/group/([^/]+)/$": uR.router.default_route,
  "^/mode/$": uR.router.routeElement("mode-viewer"),
});
ih.ready(function() { uR.router.start() });