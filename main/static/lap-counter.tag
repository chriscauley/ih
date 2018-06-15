uR.config.input_overrides.lap_timer = uR.config.input_overrides["lap-timer"] = "lap-timer";
uR.form.fields['lap-timer'] = class LapTimer extends uR.form.URInput {
  constructor(form,options) {
    options.input_tagname = "input";
    super(form,options);
    this.first_value = "lap";
    this.start = options.start();
    if (!this.choices && this.choices.length) { // #! Test that <lap-timer> works using the following
      this.choices = { label: "Lap", id: this.id+"__choice", value: "lap" };
    }
    this.first_value = this.choices[0].value;
    window.ARST = this;
    this.className += " no-label";
  }
  reset() {
    this.show_error = false;
    this.value = this.value || [[this.first_value,this.start]];
    this.field_tag.update();
  }
}

<lap-timer>
  <input id={ field.id } name={ field.name } type="hidden">
  <div class={ uR.css.btn.group_block }>
    <button each={ choice,i in choices } id={ choice.id } class={ choice.className }
            onclick={ click }>{ choice.label }</button>
  </div>
  <div>
  <div class="lap current" if={ current_lap }>
      { current_lap[0] } <span data-target_time={ current_lap[1] }></span>
    </div>
    <div each={ lap,i in past_laps }>
      { lap[0] } { lap[1] }
    </div>
  </div>
  <script>
this.choices = this.opts.field.choices;

this.on("before-mount",function() {
  this.field = this.opts.field;
  this.field.field_tag = this;
});

this.on("update", function() {
  var value = this.field && this.field.value || [];
  this.past_laps = [];
  this.root.querySelector("input").value = JSON.stringify(value);
  var last = value.length && value[value.length-1][0];
  _.each(this.choices,function(choice,ic) {
    choice.className = uR.css.btn[(last && last == choice.value)?"primary":"default"];
    choice.className += " lap__"+choice.value;
  });

  if (!value.length) { return }
  var i = value.length-1;
  this.current_lap = value[i]; // last item in value list
  var last_time = this.current_lap[1];
  while (i--) {
    var lap = value[i];
    this.past_laps.push([lap[0],String.lunch.ms2hdelta(last_time - lap[1])]);
    last_time = lap[1];
  }
})
click(e) {
  this.field.value.push([e.item.choice.value,new Date().valueOf()]);
}
  </script>
</lap-timer>