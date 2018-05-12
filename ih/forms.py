from django.utils import timezone

from lablackey.forms import RequestUserModelForm

from models import Task, TaskCompletion

class UserJsonModelForm(RequestUserModelForm):
  def undelete(self):
    self.instance.deleted = None
    self.instance.save()
  def delete(self):
    self.instance.deleted = timezone.now()
    self.instance.save()
  def get_queryset(self,*args,**kwargs):
    return super(UserJsonModelForm,self).get_queryset(*args,**kwargs).filter(deleted__isnull=True)

class TaskForm(UserJsonModelForm):
  # field_overrides = { 'per_time': 'per_time' }
  class Meta:
    model = Task
    fields = ['name','per_time','interval','alignment'] #,'group']

class TaskCompletionForm(UserJsonModelForm):
  class Meta:
    model = TaskCompletion
    fields = ['task','completed']
