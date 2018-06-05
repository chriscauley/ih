(function() {
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
        [uR.db.ih.Task,uR.db.ih.TaskGroup,uR.db.ih.Goal].forEach(m => m.objects.clear());
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
    names = names || _source_data.keys();
    items = [];
    for (var name of names) { items.push(_source_data.get(name)) }
    return uC._makeObjects('ih.Group',...names)
  }
  
  function TestLogin() {
    this.do()
      .then(login(0))
      .done()
  }

  function Test3TimesADay() {
    this.do().then(login(0,true))
      .then(createObjects("ih.TaskGroup"))
      .shiftTime("2018-01-01")
      .route("/")
    // #! TODO check groups appear at /
      .route("#!/admin/ih/Task/new/")
    // #! set time to noon
      .changeForm("ur-form form", {
        name: "Smoke",
        per_time: 3,
        interval: 1,
        group: () => uR.db.ih.TaskGroup.objects.get({name:'vices'}).id,
        alignment: 'evil',
        icon: 'smoking',
        metrics: ['timer'],
        checklist: 'bum one,new pack',
      })
      .click("#submit_button")
      .wait(".messagelist .success")
      .route("/")
      .checkResults(() => uR.db.ih.Task.objects.all().map(t => t.toJson()))
    // #! verify task appears in list
    // #! verify task is targeted for 3 hours from now
    // #! start timer
    // #! verify +0s appears
    // #! set to 15 minutes in the future
    // #! complete task
    // #! verify that task is started/complete, task-card updates
    // #! open "next" task in modal and verify target time and that started/completed are null
    // #! start+complete task
    // #! verify task is 3 hours in the future
    // #! start+completed again, this time completion should be tomorrow
      .done()
  }
  konsole.addCommands(TestLogin,Test3TimesADay);
})()
