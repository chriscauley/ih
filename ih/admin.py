# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib import admin

from models import Task, Goal

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
  list_display = ["name","interval","per_time"]

@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
  list_filter = ["task"]
  list_display = ["__unicode__","targeted","completed"]