from django.db import models
from django.contrib.auth.models import User


class ImageStore(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    image_path = models.CharField(max_length=512, default="", null=False, blank=False)
    thumbnail = models.ImageField()
    text = models.TextField()
    short_text = models.TextField()
    date = models.DateTimeField(auto_now_add=True)