from rest_framework.parsers import JSONParser
from rest_framework.views import APIView
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.validators import ValidationError
from .models import User
from .serializers import UserCreateSerializer


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
