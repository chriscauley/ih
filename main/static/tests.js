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
        [uR.db.ih.Task,uR.db.ih.TaskGroup,uR.db.ih.Goal].forEach((m) => m.objects.clear());
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

  function createBasicGroups(pass,fail) {
    var values = [
      ['chores','selkirk-rex-cat'],
      ['hygene','shower'],
      ['vices','skull'],
    ];
    var promises = [];
    uR.forEach(values,function(value) {
      promises.push(new Promise(function(resolve) {
        uR.ajax({
          url: '/api/schema/ih.TaskGroupForm/',
          data: { name: value[0], icon: value[1] },
          success: function(data) {
            ih.goals.push(new uR.db.ih.TaskGroup({values_list: data.values_list}));
            resolve();
          },
          method: "POST",
        });
      }))
    });
    Promise.all(promises).then(pass)
  }
  
  function TestLogin() {
    this.do()
      .then(login(0))
      .done()
  }

  function Test3TimesADay() {
    this.do().then(login(0,true))
      .then(createBasicGroups)
      .setPathname("/")
    // #! TODO check groups appear at /
      .setPathname("#!/admin/ih/Task/new/")
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
      .checkResults(() => uR.db.ih.Task.objects.all().map(t => t.toJson()))
      .done()
  }
  konsole.addCommands(TestLogin,Test3TimesADay);
})()
