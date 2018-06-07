from django.utils import timezone

from lablackey.forms import RequestUserModelForm

from models import Task, Goal, TaskGroup, Mode, ModeChange

class UserJsonModelForm(RequestUserModelForm):
  def undelete(self):
    self.instance.deleted = None
    self.instance.save()
  def delete(self):
    self.instance.deleted = timezone.now()
    self.instance.save()
  def get_queryset(self,*args,**kwargs):
    return super(UserJsonModelForm,self).get_queryset(*args,**kwargs).filter(deleted__isnull=True)

class TaskGroupForm(UserJsonModelForm):
  class Meta:
    model = TaskGroup
    fields = ['name','icon']

class TaskForm(UserJsonModelForm):
  def __init__(self,*args,**kwargs):
    super(TaskForm,self).__init__(*args,**kwargs)
    self.fields['group'].choices = [(g.id,str(g)) for g in TaskGroup.objects.filter(user=self.request.user)]
  # field_overrides = { 'per_time': 'per_time' }
  class Meta:
    model = Task
    fields = ['name','per_time','interval','alignment','group','icon','data']

class GoalForm(UserJsonModelForm):
  class Meta:
    model = Goal
    fields = ['task','targeted','started','completed','data']

class ModeForm(UserJsonModelForm):
  class Meta:
    model = Mode
    fields = ['name']

class ModeChangeForm(UserJsonModelForm):
  class Meta:
    model = ModeChange
    fields = ['created','mode']