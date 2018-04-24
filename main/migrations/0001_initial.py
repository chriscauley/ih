# -*- coding: utf-8 -*-
# Generated by Django 1.11.7 on 2018-04-24 02:04
from __future__ import unicode_literals

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import lablackey.db.models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Task',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created', models.DateTimeField(auto_now_add=True)),
                ('modified', models.DateTimeField(auto_now=True)),
                ('hours', models.FloatField(default=24)),
                ('name', models.CharField(max_length=128)),
                ('alignment', models.CharField(choices=[(b'good', b'good'), (b'neutral', b'neutral'), (b'evil', b'evil')], max_length=32)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'abstract': False,
            },
            bases=(models.Model, lablackey.db.models.JsonMixin),
        ),
        migrations.CreateModel(
            name='TaskCompletion',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created', models.DateTimeField(auto_now_add=True)),
                ('modified', models.DateTimeField(auto_now=True)),
                ('completed', models.DateTimeField()),
                ('task', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='main.Task')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'abstract': False,
            },
            bases=(models.Model, lablackey.db.models.JsonMixin),
        ),
    ]
