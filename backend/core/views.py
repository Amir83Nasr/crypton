from rest_framework.views import APIView
from rest_framework import viewsets, generics, permissions, status
from rest_framework.generics import RetrieveUpdateAPIView
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from decimal import Decimal

from rest_framework_simplejwt.views import TokenObtainPairView

from .permissions import IsActiveUser, IsActiveUser, IsAdminOrSelf
from .models import (
    CustomUser,
    Wallet,
    Coin,
    Asset,
    Announcement,
    ContactMessage,
    Transaction,
)
from .serializers import (
    UserSerializer,
    LoginSerializer,
    RegisterSerializer,
    WalletSerializer,
    CoinSerializer,
    ChangePasswordSerializer,
    AnnouncementSerializer,
    ContactMessageSerializer,
    BuyCoinSerializer,
    AssetSerializer,
    SellAssetSerializer,
    SwapSerializer,
    TransactionSerializer,
)


class UserViewSet(viewsets.ModelViewSet):
    queryset = CustomUser.objects.all().order_by("-id")
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated, IsActiveUser]

    def get_permissions(self):
        if self.action in ["list", "destroy", "create"]:
            return [permissions.IsAdminUser()]
        elif self.action in ["retrieve", "update", "partial_update"]:
            return [permissions.IsAuthenticated(), IsActiveUser(), IsAdminOrSelf()]
        return super().get_permissions()

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return CustomUser.objects.all().order_by("-id")
        return CustomUser.objects.filter(id=user.id)  # فقط خودش


class CurrentUserView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request):
        serializer = UserSerializer(request.user, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class WalletViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Wallet.objects.all()
    serializer_class = WalletSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # اگر کاربر ادمین بود، همه کیف پول‌ها رو ببینه
        if self.request.user.is_superuser:
            return Wallet.objects.all()
        # در غیر این صورت فقط کیف پول خودش رو ببینه
        return Wallet.objects.filter(user=self.request.user)


class WalletDetailAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        wallet = request.user.wallet
        serializer = WalletSerializer(wallet)
        return Response(serializer.data)


class CoinViewSet(viewsets.ModelViewSet):
    queryset = Coin.objects.all().order_by("market_cap_rank")
    serializer_class = CoinSerializer
    lookup_field = "symbol"

    def get_permissions(self):
        # فقط ادمین بتونه ایجاد/ویرایش/حذف کنه، بقیه فقط بخونن
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny()]


class LoginAPIView(TokenObtainPairView):
    serializer_class = LoginSerializer


class RegisterAPIView(generics.CreateAPIView):
    queryset = CustomUser.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            data = serializer.data
            return Response(
                {"message": "ثبت‌نام با موفقیت انجام شد.", "user": data},
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            old_password = serializer.validated_data["old_password"]
            new_password = serializer.validated_data["new_password"]

            if not user.check_password(old_password):
                return Response(
                    {"error": "رمز فعلی نادرست است."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            user.set_password(new_password)
            user.save()
            return Response(
                {"message": "رمز عبور با موفقیت تغییر یافت."}, status=status.HTTP_200_OK
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AnnouncementViewSet(viewsets.ModelViewSet):
    queryset = Announcement.objects.all().order_by("-created_at")
    serializer_class = AnnouncementSerializer

    def get_permissions(self):
        if self.request.method in ["POST", "PUT", "PATCH", "DELETE"]:
            return [permissions.IsAdminUser()]
        return [permissions.IsAuthenticated()]


class ContactMessageViewSet(viewsets.ModelViewSet):
    serializer_class = ContactMessageSerializer

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return ContactMessage.objects.all().order_by("-created_at")
        return ContactMessage.objects.filter(user=user).order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def get_permissions(self):
        return [permissions.IsAuthenticated()]


# ------------------------------------------------------------------------------------------


class AssetViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Asset.objects.all()
    serializer_class = AssetSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        username = self.request.query_params.get("username")

        # اگر ادمین بود و username فرستاده شده بود
        if user.is_staff and username:
            return Asset.objects.filter(user__username=username)

        # اگر ادمین بود ولی username نبود → همه دارایی‌ها
        if user.is_staff and not username:
            return Asset.objects.all()

        # اگر کاربر عادی بود → فقط دارایی خودش
        return Asset.objects.filter(user=user)


class MyAssetView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        assets = Asset.objects.filter(user=user)
        serializer = AssetSerializer(assets, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class BuyCoinAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = BuyCoinSerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            user = request.user
            coin = Coin.objects.get(id=serializer.validated_data["coin_id"])
            amount = serializer.validated_data["amount"]
            total_value = coin.current_price * amount

            # کم کردن پول از کیف پول
            wallet = user.wallet
            wallet.balance -= total_value
            wallet.save()

            # اضافه کردن به دارایی‌ها
            asset, created = Asset.objects.get_or_create(
                user=user, coin=coin, defaults={"amount": amount}
            )
            if not created:
                asset.amount += amount
                asset.save()

            Transaction.objects.create(
                user=user,
                transaction_type="buy",
                coin=coin,
                total_value=total_value,
            )

            return Response(
                {"message": "خرید با موفقیت انجام شد"}, status=status.HTTP_200_OK
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SellAssetAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = SellAssetSerializer(
            data=request.data, context={"request": request}
        )
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"message": "فروش با موفقیت انجام شد", "data": serializer.data},
                status=status.HTTP_200_OK,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SwapView(APIView):
    def post(self, request):
        serializer = SwapSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        data = serializer.validated_data
        from_symbol = data["from_symbol"]
        to_symbol = data["to_symbol"]
        amount = data["amount"]

        if from_symbol == to_symbol:
            return Response({"detail": "نمیشه دو ارز مشابه رو سواپ کرد."}, status=400)

        try:
            from_coin = Coin.objects.get(symbol=from_symbol)
            to_coin = Coin.objects.get(symbol=to_symbol)
        except Coin.DoesNotExist:
            return Response({"detail": "رمزارز نامعتبر است."}, status=400)

        try:
            from_asset = Asset.objects.get(user=user, coin=from_coin)
        except Asset.DoesNotExist:
            return Response({"detail": f"شما هیچ {from_symbol} ندارید."}, status=400)

        if from_asset.amount < amount:
            return Response({"detail": "مقدار کافی برای سواپ ندارید."}, status=400)

        # نرخ تبدیل
        rate = Decimal(from_coin.current_price) / Decimal(to_coin.current_price)
        received_amount = amount * rate

        # به‌روزرسانی دارایی‌ها
        from_asset.amount -= amount
        if from_asset.amount <= 0:
            from_asset.delete()
        else:
            from_asset.save()

        to_asset, created = Asset.objects.get_or_create(
            user=user, coin=to_coin, defaults={"amount": received_amount}
        )
        if not created:
            to_asset.amount += received_amount
            to_asset.save()

        return Response(
            {
                "swapped": str(amount),
                "from_symbol": from_symbol,
                "received": str(received_amount),
                "to_symbol": to_symbol,
            },
            status=200,
        )

class UserTransactions(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        transactions = Transaction.objects.filter(user=user).order_by('-timestamp')
        serializer = TransactionSerializer(transactions, many=True)
        return Response(serializer.data)