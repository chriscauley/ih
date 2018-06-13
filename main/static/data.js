(function() {
  function _getGroup(name) {
    if (uC.USE_GROUPS) { return () => uR.db.ih.TaskGroup.objects.get({name:name}).id }
  }

  function FastMap(field_name,items,value_keys) {
    if (value_keys) {
      items = items.map(function(values) {
        var d = {};
        uR.forEach(values,function(value,i) { d[value_keys[i]] = value; })
        return d;
      })
    }
    return new Map(items.map((i) => [i[field_name],i]));
  }

  uC.SOURCE_DATA = {};

  uC.SOURCE_DATA['ih.Mode'] = new FastMap(
    'name',
    [['sleep'],['work'],['travel'],['exercise'],['play']],
    ['name']
  )

  uC.SOURCE_DATA['ih.TaskGroup'] = new FastMap(
    'name', [
      ['chores','selkirk-rex-cat'],
      ['hygene','shower'],
      ['vices','skull']
    ],
    ['name','icon']
  )

  uC.SOURCE_DATA['ih.Task'] = new FastMap(
    'name', [
      ['smoke',3,1,_getGroup('vices'),'evil','smoking',
       ['timer'],'bum one,new pack'],
      ['shower',1,3,_getGroup('hygene'),'neutral',null,
       ['timer'],"shave, wash hair, condition hair, private hair"],
      ['press button three times',1,3,null,'neutral'],
    ],
    ['name','per_time','interval','group','alignment','icon','metrics','checklist']
  )

  uC._makeObjects = function _makeObjects(model_key,...items) {
    var item2data = {
      "function": v => v(),
      "array": v => v.join(","),
      "string": v => v,
      "number": v => v,
      "object": v => v,
      "undefined": v => v,
    }
    function test(pass,fail) {
      var promises = [];
      uR.forEach(items,function(item) {
        var data = {};
        for (var key in item) {
          data[key] = item2data[typeof item[key]](item[key]);
        }
        promises.push(new Promise(function(resolve) {
          uR.ajax({
            url: `/api/schema/${model_key}Form/`,
            data: new uR.db[model_key](data).toJson(),
            success: function(response_data) {
              new uR.db[model_key]({ values_list: response_data.values_list});
              resolve();
            },
            method: "POST",
          });
        }))
      });
      Promise.all(promises).then(pass);
    }
    test._name = `makeObject ${model_key} x ${items.length}`;
    return test;o
  }
})()