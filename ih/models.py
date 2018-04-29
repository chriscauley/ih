from django.contrib.postgres.fields import JSONField
from django.db import models
from django.utils import timezone

from lablackey.db.models import UserModel

#! todo: move both these choices into the front end app

ALIGNMENT_CHOICES = [
  ("good","good"),
  ("neutral","neutral"),
  ("evil","evil"),
]

FREQUENCY_CHOICES = [ 1, 2, 3, 4, 5, 6, 7,"weekly","monthly","twice_monthly" ];
FREQUENCY_CHOICES = [(str(a),str(a)) for a in FREQUENCY_CHOICES]

class Task(UserModel):
  json_fields = ['id', #! TODO should be in self.as_json and self.as_json_list
                 'name','per_time','frequency','alignment']
  name = models.CharField(max_length=128)
  per_time = models.IntegerField(default=1)
  frequency = models.CharField(max_length=32,choices=FREQUENCY_CHOICES)
  alignment = models.CharField(max_length=32,choices=ALIGNMENT_CHOICES)
  __unicode__ = lambda self: self.name

class TaskCompletion(UserModel):
  task = models.ForeignKey(Task)
  completed = models.DateTimeField(default=timezone.now)
  __unicode__ = lambda self: "%s %s @ %s"%(self.user,self.task,self.completed)