from .models import ImageStore
from django.db.models.signals import post_save
from django.dispatch import receiver
from textblob import TextBlob


# Database trigger runs on every new ImageStore created
@receiver(post_save, sender=ImageStore)
def analiseText(sender: ImageStore, instance: ImageStore, created: bool, **kwargs):
    if created:
        # Find noun phrases and update the short_text field
        blob = TextBlob(text=instance.text)
        short_text: str = ""
        for item in blob.noun_phrases:
            short_text = short_text + item + " "
        instance.short_text = short_text
        instance.save()
