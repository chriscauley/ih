(function() {
  var SHIFT_TO = moment().startOf("week").format();
  function login(index,reset=true) {
    var [username,password] = DUMMY_USERS[index];
    function login(pass,fail) {
      uR.ajax({
        url: '/api/login/', // #! TODO make this a setting
        data: { username: username, password: password }, // #! TODO maybe username (key) should be customizable?
        method: "POST",
        success: () => pass(),
      });
    }
    if (reset) {
      return function loginWithReset(pass,fail) {
        'Task,TaskGroup,Goal,Mode'.split(',').forEach(m => uR.db.ih[m].objects.clear());
        // [uR.db.ih.Task,uR.db.ih.TaskGroup,uR.db.ih.Goal].forEach(m => console.log(m.objects.all()));
        uR.ajax({
          url: '/api/test/reset/',
          data: { reset_email: username },
          success: () => login(pass,fail),
        });
        index = index || 0;
      }
    }
    return login;
  }

  function createObjects(model_key,...names) {
    var _source_data = uC.SOURCE_DATA[model_key];
    names = names.length?names:Array.from(_source_data.keys());
    items = [];
    for (var name of names) { items.push(_source_data.get(name)) }
    return uC._makeObjects(model_key,...items)
  }
  
  function TestLogin() {
    this.do()
      .then(login(0))
      .done()
  }

  function TestModes() {
    this.do().then(login(0,true))
      .shiftTime(SHIFT_TO)
      .then(createObjects("ih.Mode"))
      .route("/mode/")
      .checkResults("mode-viewer")
  }

  function TestTimer() {
    uC.USE_GROUPS = false;
    this.do().then(login(0,true))
      .shiftTime(SHIFT_TO)
      .then(createObjects("ih.Task",'smoke'))

      .comment("Timer should not be clicked.")
      .route("/").wait(1000)
      .checkResults(".task_smoke")

      // .comment("Timer @+0s.")
      // .click(".task_smoke .fa-clock-o").wait(1000)
      // .checkResults(".task_smoke")

      // .comment("Timer @+60s.")
      // .shiftTime(60,"seconds").wait(1000)
      // .checkResults(".task_smoke")

      // .comment("Timer Closed.")
      // .click(".task_smoke .fa-clock-o").wait(1000)
      // .checkResults(".task_smoke")
  }

  function Test3TimesADay() {
    uC.USE_GROUPS = false;
    this.do().then(login(0,true))
      .shiftTime(SHIFT_TO)
      .then(createObjects("ih.Task",'smoke'))
      .route("/")
      .wait(1000)
      .comment("First click")
      .checkResults(".task_smoke")
      .shiftTime(3601,"seconds")
      .wait(1000)
      .checkResults(".task_smoke")
      .click(".task_smoke .fa-clock-o")
      .wait(1000)
      .checkResults(".task_smoke")
    // #! start timer
    // #! verify +0s appears
    // #! set to 15 minutes in the future
    // #! complete task
    // #! verify that task is started/complete, task-card updates
    // #! open "next" task in modal and verify target time and that started/completed are null
    // #! start+complete task
    // #! verify task is 3 hours in the future
    // #! start+completed again, this time completion should be tomorrow
  }
  konsole.addCommands(TestLogin,TestTimer,Test3TimesADay,TestModes);
})()
