from django.conf import settings
from django.conf.urls import include, url

from django.contrib.auth import urls as auth_urls
import lablackey.urls,lablackey.views

urlpatterns = [
  url(r'^auth/',include(auth_urls)),
  url(r'',include(lablackey.urls)),
  url(r'^group/(\d+)/',lablackey.views.render_template,kwargs={'template': "base.html"}),
  url(r'^modechange/',lablackey.views.render_template,kwargs={'template': "base.html"}),
]
