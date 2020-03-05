from .models import ImageStore
from django.db.models.signals import post_save
from django.dispatch import receiver
from textblob import TextBlob


@receiver(post_save, sender=ImageStore)
def analiseText(sender: ImageStore, instance: ImageStore, created: bool, **kwargs):
    if created:
        blob = TextBlob(text=instance.text)
        print("Finding noun phrases")
        print(blob.noun_phrases)
        short_text: str = ""
        for item in blob.noun_phrases:
            short_text = short_text + item + " "
        instance.short_text = short_text
        instance.save()

    print("analiseText")
