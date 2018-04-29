# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib import admin

from models import Task, TaskCompletion

# Register your models here.

admin.register(Task)(admin.ModelAdmin)
admin.register(TaskCompletion)(admin.ModelAdmin)