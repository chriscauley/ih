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
        var models = 'Task,TaskGroup,Goal,Mode'.split(",").map(s=>uR.db.ih[s]);
        models.forEach(m => m.objects.clear());
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

      .comment("Timer @+0s.")
      .click(".task_smoke .fa-clock-o").wait(1000)
      .checkResults(".task_smoke")

      .comment("Timer @+60s.")
      .shiftTime(60,"seconds").wait(1000)
      .checkResults(".task_smoke")

      .comment("Timer Closed.")
      .click(".task_smoke .fa-clock-o").wait(1000)
      .checkResults(".task_smoke")
  }

  function TestLapTimer() {
    uC.USE_GROUPS = false;
    var s = ".task_running"

    this.do().then(login(0,true))
      .shiftTime(SHIFT_TO)
      .then(createObjects("ih.Task","running"))
      .route("/").wait(1000)

      .comment("Timer +0s")
      .click(s+" .fa-clock-o").wait(1000)
      .checkResults(s)

      .comment("Timer +30s")
      .shiftTime(30,"seconds").wait(1000)
      .checkResults(s)

      .comment("Switch to running")
      .click(s+" .lap__run").wait(1000)
      .checkResults(s)

      .comment("Run 4x 3 minute laps")
      .shiftTime(3,"minutes")
      .click(s+" .lap__run")
      .shiftTime(3,"minutes")
      .click(s+" .lap__run")
      .shiftTime(3,"minutes")
      .click(s+" .lap__run")
      .shiftTime(3,"minutes")
      .checkResults(s)

      .comment("Jog 5 minutes")
      .click(s+" .lap__jog")
      .shiftTime(5,"minutes").wait(1000)
      .checkResults(s)

      .comment("Finish run")
      .click(s+" .fa-clock-o").wait(1000)
      .checkResults(s)
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
  konsole.addCommands(
    TestLogin,
    TestTimer,
    TestLapTimer,
    Test3TimesADay,
    TestModes,
  );
})()
