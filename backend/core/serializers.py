from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from django.db import transaction
from django.contrib.auth import authenticate, get_user_model
from decimal import Decimal


from .models import (
    CustomUser,
    Asset,
    Wallet,
    Coin,
    Announcement,
    ContactMessage,
    Transaction,
)

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = CustomUser
        fields = [
            "id",
            "username",
            "password",
            "name",
            "family",
            "age",
            "gender",
            "is_active",
            "is_superuser",
        ]
        read_only_fields = ["id", "is_superuser"]

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = CustomUser(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance


class LoginSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        username = attrs.get("username")
        password = attrs.get("password")

        if not username or not password:
            raise serializers.ValidationError(
                {"detail": "نام کاربری و رمز عبور الزامی است."}
            )

        user = authenticate(username=username, password=password)

        if not user:
            if User.objects.filter(username=username).exists():
                raise serializers.ValidationError({"detail": "رمز عبور اشتباه است."})
            else:
                raise serializers.ValidationError(
                    {"detail": "کاربری با این نام کاربری یافت نشد."}
                )

        self.user = user

        data = super().validate(attrs)

        data["role"] = "admin" if user.is_staff else "user"

        return data


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = CustomUser
        fields = ["username", "password", "name", "family", "age", "gender"]

    def validate_username(self, value):
        if CustomUser.objects.filter(username=value).exists():
            # فقط متن خطا رو بده، نه دیکشنری
            raise serializers.ValidationError("این نام کاربری قبلا استفاده شده است.")
        return value

    def validate_age(self, value):
        if value is not None and value < 10:
            raise serializers.ValidationError("سن شما باید بیشتر از 10 سال باشد.")
        return value

    def create(self, validated_data):
        try:
            return CustomUser.objects.create_user(**validated_data)
        except Exception as e:
            # اینجا چون خطا مربوط به کلیت عملیات ثبت‌نامه، به صورت دیکشنری با کلید non_field_errors بده
            raise serializers.ValidationError(
                {"non_field_errors": [f"خطا در ثبت‌نام کاربر: {str(e)}"]}
            )

    def to_representation(self, instance):
        data = super().to_representation(instance)
        refresh = RefreshToken.for_user(instance)
        data["access"] = str(refresh.access_token)
        data["refresh"] = str(refresh)
        return data


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)

    def validate_new_password(self, value):
        if len(value) < 4:
            raise serializers.ValidationError("رمز جدید باید حداقل ۸ کاراکتر باشد.")
        return value


class AnnouncementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Announcement
        fields = ["id", "title", "message", "created_at"]


class ContactMessageSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)
    name = serializers.CharField(source="user.name", read_only=True)
    family = serializers.CharField(source="user.family", read_only=True)

    class Meta:
        model = ContactMessage
        fields = [
            "id",
            "username",
            "name",
            "family",
            "message",
            "stars",
            "created_at",
        ]
        read_only_fields = ["user", "username", "name", "family"]


class CoinSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coin
        fields = "__all__"


class WalletSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = Wallet
        fields = ["id", "username", "balance"]
        read_only_fields = ["id", "username"]


# -----------------------------------------------------------------------


class CoinMiniSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coin
        fields = ["symbol", "name", "image", "current_price"]


class AssetSerializer(serializers.ModelSerializer):
    coin = CoinMiniSerializer(read_only=True)
    username = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = Asset
        fields = ["id", "username", "coin", "amount"]


class BuyCoinSerializer(serializers.Serializer):
    coin_id = serializers.IntegerField()
    amount = serializers.DecimalField(max_digits=20, decimal_places=8)

    def validate(self, data):
        user = self.context["request"].user
        coin = Coin.objects.get(id=data["coin_id"])
        total_price = coin.current_price * data["amount"]
        if user.wallet.balance < total_price:
            raise serializers.ValidationError("موجودی کیف پول کافی نیست.")
        return data


class SellAssetSerializer(serializers.Serializer):
    coin_symbol = serializers.CharField()
    amount = serializers.FloatField(min_value=0.0001)

    def validate(self, attrs):
        request = self.context["request"]
        user = request.user
        coin_symbol = attrs["coin_symbol"]
        amount = attrs["amount"]

        try:
            coin = Coin.objects.get(symbol__iexact=coin_symbol)
            asset = Asset.objects.get(user=user, coin=coin)
        except Coin.DoesNotExist:
            raise serializers.ValidationError("رمز ارز موردنظر پیدا نشد")
        except Asset.DoesNotExist:
            raise serializers.ValidationError("شما این رمز ارز را در دارایی خود ندارید")

        if asset.amount < amount:
            raise serializers.ValidationError("مقدار رمز ارز کافی نیست")

        attrs["coin"] = coin
        attrs["asset"] = asset
        return attrs

    @transaction.atomic
    def save(self, **kwargs):
        user = self.context["request"].user
        wallet = user.wallet
        coin = self.validated_data["coin"]
        asset = self.validated_data["asset"]

        coin_price = coin.current_price
        amount = Decimal(str(self.validated_data["amount"]))
        total_value = amount * coin_price

        # کسر از دارایی
        asset.amount -= amount
        if asset.amount <= 0:
            asset.delete()
            asset_amount = Decimal("0")
        else:
            asset.save()
            asset_amount = asset.amount

        # اضافه به کیف پول
        wallet.balance += total_value
        wallet.save()

        # 📌 ثبت تراکنش
        Transaction.objects.create(
            user=user,
            transaction_type="sell",
            coin=coin,
            total_value=total_value,
        )

        return {
            "wallet_balance": wallet.balance,
            "asset_balance": asset_amount,
            "coin": coin.symbol,
            "sold_amount": amount,
            "total_value": total_value,
        }


class SwapSerializer(serializers.Serializer):
    from_symbol = serializers.CharField()
    to_symbol = serializers.CharField()
    amount = serializers.DecimalField(max_digits=20, decimal_places=8)


class TransactionSerializer(serializers.ModelSerializer):
    coin_symbol = serializers.CharField(source="coin.symbol", read_only=True)
    coin_name = serializers.CharField(source="coin.name", read_only=True)

    class Meta:
        model = Transaction
        fields = [
            "id",
            "timestamp",
            "transaction_type",
            "total_value",
            "coin_symbol",
            "coin_name",
        ]
