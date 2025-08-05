from django.contrib.auth.models import (
    AbstractBaseUser,
    PermissionsMixin,
    BaseUserManager,
)
from django.core.exceptions import ValidationError
from django.db import models
from decimal import Decimal


class CustomUserManager(BaseUserManager):
    def create_user(self, username, password=None, **extra_fields):
        if not username:
            raise ValueError("نام کاربری الزامی است")
        user = self.model(username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        Wallet.objects.create(user=user)
        return user

    def create_superuser(self, username, password, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if not extra_fields.get("is_staff"):
            raise ValueError("سوپریوزر باید is_staff=True داشته باشد.")
        if not extra_fields.get("is_superuser"):
            raise ValueError("سوپریوزر باید is_superuser=True داشته باشد.")

        return self.create_user(username, password, **extra_fields)


class CustomUser(AbstractBaseUser, PermissionsMixin):
    GENDER_CHOICES = [("male", "مرد"), ("female", "زن")]

    username = models.CharField(max_length=150, unique=True)
    name = models.CharField(max_length=100, blank=True)
    family = models.CharField(max_length=100, blank=True)
    age = models.PositiveIntegerField(null=True, blank=True)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, blank=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    USERNAME_FIELD = "username"
    REQUIRED_FIELDS = ["name", "family"]

    objects = CustomUserManager()

    def __str__(self):
        return self.username + " - " + self.name + " " + self.family


class Coin(models.Model):
    symbol = models.CharField(max_length=15, unique=True)
    name = models.CharField(max_length=50)
    image = models.URLField()
    current_price = models.DecimalField(max_digits=20, decimal_places=4)
    market_cap = models.BigIntegerField()
    total_volume = models.BigIntegerField()
    market_cap_rank = models.IntegerField()
    ath = models.DecimalField(max_digits=20, decimal_places=4)
    atl = models.DecimalField(max_digits=20, decimal_places=4)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} ({self.symbol})"


class Wallet(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE)
    balance = models.DecimalField(max_digits=20, decimal_places=4, default=0)

    def __str__(self):
        return f"{self.user.username}'s Wallet: {self.balance} USD"


class Announcement(models.Model):
    title = models.CharField(max_length=255)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title


class ContactMessage(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    message = models.TextField()
    stars = models.PositiveSmallIntegerField()  # مثلاً از ۱ تا ۵
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} ({self.stars}⭐)"


class Asset(models.Model):
    user = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name="assets"
    )
    coin = models.ForeignKey(Coin, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=20, decimal_places=8)

    class Meta:
        unique_together = ("user", "coin")

    def __str__(self):
        return f"{self.user.username} - {self.coin.symbol} - {self.amount}"


class Transaction(models.Model):
    TRANSACTION_TYPES = [
        ("buy", "خرید"),
        ("sell", "فروش"),
    ]

    user = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name="transactions"
    )
    transaction_type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    coin = models.ForeignKey("Coin", on_delete=models.CASCADE)
    total_value = models.DecimalField(
        max_digits=30,
        decimal_places=8,
        help_text="مجموع پول جابجا شده",
    )
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.transaction_type} - {self.coin.symbol} - {self.total_value}"
