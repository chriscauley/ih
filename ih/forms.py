from lablackey.forms import RequestUserModelForm

from models import Task, TaskCompletion

class TaskForm(RequestUserModelForm):
  # field_overrides = { 'per_time': 'per_time' }
  class Meta:
    model = Task
    fields = ['name','per_time','frequency','alignment']

class TaskCompletionForm(RequestUserModelForm):
  class Meta:
    model = TaskCompletion
    fields = ['task','completed']