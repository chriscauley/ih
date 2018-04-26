from lablackey.forms import RequestUserModelForm

from models import Task

class TaskForm(RequestUserModelForm):
  # field_overrides = { 'per_time': 'per_time' }
  class Meta:
    model = Task
    fields = ['name','per_time','frequency','alignment']
