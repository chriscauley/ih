# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib import admin

from models import Task, TaskCompletion

admin.register(Task)(admin.ModelAdmin)

@admin.register(TaskCompletion)
class TaskCompletionAdmin(admin.ModelAdmin):
  list_display = ["__unicode__","deleted"]