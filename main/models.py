from django.contrib.postgres.fields import JSONField
from django.db import models

from lablackey.db.models import UserModel

ALIGNMENT_CHOICES = [
  ("good","good"),
  ("neutral","neutral"),
  ("evil","evil"),
]

class Task(UserModel):
  hours = models.FloatField(default=24)
  name = models.CharField(max_length=128)
  alignment = models.CharField(max_length=32,choices=ALIGNMENT_CHOICES)
  __unicode__ = lambda self: self.name

class TaskCompletion(UserModel):
  task = models.ForeignKey(Task)
  completed = models.DateTimeField()
  __unicode__ = lambda self: "%s %s @ %s"%(self.user,self.task,self.completed)