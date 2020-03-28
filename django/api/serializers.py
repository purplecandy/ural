from .models import User, ImageStore
from rest_framework.serializers import ModelSerializer


class UserCreateSerializer(ModelSerializer):
    class Meta:
        model = User
        fields = ('username', 'password')

    def create(self, validated_data):
        user = User(**validated_data)
        user.set_password(validated_data["password"])
        user.save()
        return user


class ImageStoreSerializer(ModelSerializer):
    class Meta:
        model = ImageStore
        fields = ("user", "image_path", "thumbnail", "text", "short_text")


class ImageStoreMetaSerializer(ModelSerializer):
    class Meta:
        model = ImageStore
        fields = ("id","image_path", "thumbnail")
