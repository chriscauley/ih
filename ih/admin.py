# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib import admin

from models import Task, Goal, TaskGroup, Mode, ModeChange

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
  list_display = ["name","interval","per_time"]
  list_per_page = 100

@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
  list_filter = ["task",'user']
  list_display = ["__unicode__","targeted","completed"]
  list_per_page = 100

@admin.register(TaskGroup)
class TaskGroupAdmin(admin.ModelAdmin):
  list_display = ['name','user','icon']

@admin.register(Mode)
class ModeAdmin(admin.ModelAdmin):
  list_display = ['id','name']
  list_editable = ['name']

@admin.register(ModeChange)
class ModeChangeAdmin(admin.ModelAdmin):
  list_display = ['mode','created']
  list_editable = ['created']