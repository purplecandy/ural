from rest_framework.parsers import JSONParser
from rest_framework.views import APIView
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.validators import ValidationError
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from django.contrib.postgres.search import SearchQuery, SearchVector, SearchRank
import base64
from .models import ImageStore
from .serializers import UserCreateSerializer, ImageStoreMetaSerializer
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

    def get(self, request: Request) -> Response:
        queryset = ImageStore.objects.filter(user=request.user)
        serializer = ImageStoreMetaSerializer(queryset, many=True)
        return Response(data=serializer.data, status=200)

    def post(self, request: Request) -> Response:
        if not request.data["thumbnail"]:
            return Response(data={"message": "No image data provided"}, status=404)

        hash_code: int = hash(request.data["image_path"])

        try:
            ImageStore.objects.get(hash_code=str(hash_code))
        except ImageStore.DoesNotExist:
            pass
        else:
            return Response(data={"message": "File already exists"}, status=201)

        # Set file path
        loc = os.path.join(settings.MEDIA_ROOT, request.data["filename"])
        # Write the file in filesystem
        thumbnail = open(loc, "wb")
        thumbnail.write(base64.b64decode(request.data["thumbnail"]))
        thumbnail.close()
        # create a new record
        ImageStore.objects.create(user=request.user,
                                  image_path=request.data["image_path"],
                                  thumbnail=request.data["filename"],
                                  text=request.data["text"],
                                  short_text="",
                                  hash_code=str(hash_code)
                                  )

        return Response(data={"message": "Created successfully"}, status=201)


class ImageSearchView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        if not request.GET.get('query'):
            return Response(data={"message": "Invalid query"}, status=400)

        query = SearchQuery(request.GET.get('query'))
        vector = SearchVector("text", weight="C") + SearchVector("short_text", weight="A")
        queryset = ImageStore.objects.filter(user=request.user).annotate(rank=SearchRank(vector, query)).filter(
            rank__gt=0).order_by(
            '-rank')
        serializer = ImageStoreMetaSerializer(queryset, many=True)
        return Response(data=serializer.data, status=200)
