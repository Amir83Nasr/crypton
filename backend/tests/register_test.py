import pytest
from rest_framework.exceptions import ValidationError
from core.serializers import RegisterSerializer
from core.models import CustomUser
from unittest.mock import patch
from rest_framework_simplejwt.tokens import RefreshToken

@pytest.mark.django_db
class TestRegisterSerializer:
    
    def test_validate_username_already_exists(self):
        CustomUser.objects.create_user(username="taken", password="1234", name="Ali", family="Rezaei")
        serializer = RegisterSerializer()
        with pytest.raises(ValidationError) as exec:
            serializer.validate_username("taken")
        assert "این نام کاربری قبلا استفاده شده است." in str(exec.value)
    
    def test_validate_username_unique(self):
        serializer = RegisterSerializer()
        assert serializer.validate_username("unique_user") == "unique_user"

    def test_validate_age_under_10(self):
        serializer = RegisterSerializer()
        with pytest.raises(ValidationError) as exec:
            serializer.validate_age(9)
        assert "سن شما باید بیشتر از 10 سال باشد." in str(exec.value)

    def test_validate_age_valid(self):
        serializer = RegisterSerializer()
        assert serializer.validate_age(15) == 15

    def test_validate_age_none(self):
        setializer = RegisterSerializer()
        assert setializer.validate_age(None) == None

    def test_create_success(self):
        data = {
            "username" : 'new_user',
            "password" : "safe_pass",
            "name" : "Ali",
            "family" : "Rezaei",
            "age" : 25,
            "gender" : "male"
            }
        serializer = RegisterSerializer()
        user = serializer.create(data)
        assert CustomUser.objects.filter(username="new_user").exists()
        assert user.name == "Ali"
        assert user.family == "Rezaei"
        assert user.age == 25
        assert user.gender == "male"

    def test_create_failure(self):
        serializer = RegisterSerializer()
        data = {
            "username" : "fail_user",
            "password" : "pass",
            "name" : "Test",
            "family" : "User",
            "age" : 20,
            "gender" : "female"
        }
        
        with patch("core.serializers.CustomUser.objects.create_user", side_effect=Exception("DB error")):
            with pytest.raises(ValidationError) as exec:
                serializer.create(data)
            assert "خطا در ثبت" in str(exec.value)

    def test_to_representation_includes_tokens(self):
        user = CustomUser.objects.create_user(
            username="jwt_user",
            password="pass",
            name="A",
            family="B",
            age=20,
            gender="male",
        )
        serializer = RegisterSerializer()
        data = serializer.to_representation(user)

        refresh = RefreshToken.for_user(user)

        assert "access" in data
        assert "refresh" in data
        assert data["access"].count(".") == 2
        assert data["refresh"].count(".") == 2
