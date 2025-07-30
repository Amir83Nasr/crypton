import pytest
from django.contrib.auth import get_user_model
from rest_framework.exceptions import ValidationError
from core.serializers import LoginSerializer 

User = get_user_model()

@pytest.mark.django_db
class TestLoginSerializers:

    def setup_method(self):
        self.password = "securepass"
        self.admin_user = User.objects.create_user(
            username="admin", password=self.password, is_staff=True
        )
        self.regular_user = User.objects.create_user(
            username="john", password="johnpass", is_staff=False
        )

    def test_login_success_admin(self):
        serializer = LoginSerializer()
        result = serializer.validate({"username" : "admin", "password" : "securepass"})
        assert result["role"] == "admin"

    def test_login_success_user(self):
        serializer = LoginSerializer()
        result = serializer.validate({"username" : "john", "password" : "johnpass"})
        assert result["role"] == "user"

    def test_missing_username(self):
        serializer = LoginSerializer()
        with pytest.raises(ValidationError) as exec:
            serializer.validate({"password" : "anything"})

        assert "نام کاربری و رمز عبور الزامی است." in str(exec.value)

    def test_missing_password(self):
        serializer = LoginSerializer()
        with pytest.raises(ValidationError) as exec:
            serializer.validate({"username" : "anything"})
        
        assert "نام کاربری و رمز عبور الزامی است." in str(exec.value)

    def test_wrong_password(self):
        serializer = LoginSerializer()
        with pytest.raises(ValidationError) as exec:
            serializer.validate({"username" : "admin", "password" : "wrongpass" })
        
        assert "رمز عبور اشتباه است." in str(exec.value)

    def test_wrong_username(self):
        serializer = LoginSerializer()
        with pytest.raises(ValidationError) as exec:
            serializer.validate({"username" : "wronguser", "password" : "anything"})
        
        assert "کاربری با این نام کاربری یافت نشد." in str(exec.value)

