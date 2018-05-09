# -*- coding: utf-8 -*-
# Generated by Django 1.11.7 on 2018-05-07 02:53
from __future__ import unicode_literals

from django.db import migrations, models
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('ih', '0002_auto_20180424_1959'),
    ]

    operations = [
        migrations.RenameField('task','frequency','interval'),
        migrations.AlterField(
            model_name='taskcompletion',
            name='completed',
            field=models.DateTimeField(default=django.utils.timezone.now),
        ),
    ]