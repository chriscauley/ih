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

INTERVAL_CHOICES = [ 1, 2, 3, 4, 5, 6, 7,
                     "twice_monthly","monthly","every_two_months","every_three_months" ];
INTERVAL_CHOICES = [(str(a),str(a)) for a in INTERVAL_CHOICES]

class JsonModel(UserModel):
  created = models.DateTimeField(default=timezone.now)
  updated = models.DateTimeField(auto_now=True)
  deleted = models.DateTimeField(null=True,blank=True)
  class Meta:
    abstract = True

class TaskGroup(JsonModel):
  name = models.CharField(max_length=64)
  icon = models.CharField(max_length=64,null=True,blank=True)
  __unicode__ = lambda self: self.name

class Task(JsonModel):
  json_fields = ['id', #! TODO should be in self.as_json and self.as_json_list
                 'name','per_time','interval','alignment', 'group']
  group = models.ForeignKey("TaskGroup",null=True,blank=True)
  name = models.CharField(max_length=128)
  per_time = models.IntegerField(default=1)
  interval = models.CharField(max_length=32,choices=INTERVAL_CHOICES)
  alignment = models.CharField(max_length=32,choices=ALIGNMENT_CHOICES)
  icon = models.CharField(max_length=64,null=True,blank=True)
  data = JSONField(default=dict,null=True,blank=True)
  __unicode__ = lambda self: self.name

class Goal(JsonModel):
  task = models.ForeignKey(Task)
  targeted = models.DateTimeField(default=timezone.now)
  started = models.DateTimeField(null=True,blank=True)
  data = JSONField(default=dict,null=True,blank=True)
  completed = models.DateTimeField(null=True,blank=True)
  __unicode__ = lambda self: "%s %s @ %s"%(self.user,self.task,self.completed)

# currently unused
class NoSQLModel(JsonModel):
  data = JSONField(default=dict,null=True,blank=True)
  ur_model = models.CharField(max_length=255)

class Mode(JsonModel):
  name = models.CharField(max_length=32)
  __unicode__ = lambda self: "%s %s"%(self.name,self.user)
  class Meta:
    ordering = ('name',)

class ModeChange(JsonModel):
  mode = models.ForeignKey("Mode")
  __unicode__ = lambda self: "%s@%s"%(self.mode,self.created)
  class Meta:
    ordering = ('created',)