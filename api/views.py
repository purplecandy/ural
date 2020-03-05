from rest_framework.parsers import JSONParser
from rest_framework.views import APIView
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.validators import ValidationError
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
import base64
from .models import User, ImageStore
from .serializers import UserCreateSerializer, ImageStoreSerializer
import os
from django.conf import settings


class UserView(APIView):
    parser_classes = [JSONParser]

    def post(self, request: Request) -> Response:
        serializer = UserCreateSerializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except ValidationError:
            return Response(data={"message": "The user already exist"}, status=400)
        else:
            serializer.create(validated_data=serializer.validated_data)
            return Response(data={"message": "User created successfully"}, status=201)


class ImageStoreView(APIView):
    parser_classes = [JSONParser]
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        if not request.data["thumbnail"]:
            return Response(data={"message": "No image data provided"}, status=404)

        # decode image
        # thumbnail = open("temp.jpg", "wb")

        # reassign modified data and user id
        # request.data["thumbnail"] = thumbnail
        request.data["user"] = request.user.id

        # validate incoming data
        # serializer = ImageStoreSerializer(data=request.data)
        # serializer.is_valid(raise_exception=True)

        # create a new record
        # serializer.create(validated_data=serializer.validated_data)
        # t =request.data["thumbnail"]
        loc = os.path.join(settings.MEDIA_ROOT, request.data["filename"])
        thumbnail = open(loc, "wb")
        thumbnail.write(base64.b64decode(request.data["thumbnail"]))
        thumbnail.close()

        ImageStore.objects.create(user=request.user, image_path=request.data["image_path"],
                                  thumbnail=request.data["filename"], text=request.data["text"],
                                  short_text="")

        return Response(data={"message": "Created successfully"}, status=201)
