# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib import admin

from models import Task, Goal

admin.register(Task)(admin.ModelAdmin)

@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
  list_display = ["__unicode__","deleted"]