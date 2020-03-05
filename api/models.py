from django.db import models
from django.contrib.auth.models import User


class ImageStore(models.Model):
    imagePath = models.CharField(max_length=512, default="")
    thumbnail = models.ImageField()
    text = models.TextField()
    short_text = models.TextField()
   