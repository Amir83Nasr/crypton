from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .views import (
    UserViewSet,
    CurrentUserView,
    WalletViewSet,
    WalletDetailAPIView,
    CoinViewSet,
    RegisterAPIView,
    LoginAPIView,
    ChangePasswordView,
    AnnouncementViewSet,
    ContactMessageViewSet,
    BuyCoinAPIView,
    SellAssetAPIView,
    SwapView,
    AssetViewSet,
    MyAssetView,
    UserTransactions,
)

router = DefaultRouter()

router.register(r"users", UserViewSet, basename="users")
router.register(r"wallets", WalletViewSet, basename="wallets")
router.register(r"assets", AssetViewSet, basename="assets")

router.register(r"coins", CoinViewSet, basename="coins")

router.register(r"announcements", AnnouncementViewSet, basename="announcements")
router.register(r"contact-messages", ContactMessageViewSet, basename="contact-messages")


urlpatterns = [
    path("", include(router.urls)),
    path("register/", RegisterAPIView.as_view(), name="register"),
    path("login/", LoginAPIView.as_view(), name="login"),
    path("token/refresh", TokenRefreshView.as_view(), name="token_refresh"),
    path("change-password/", ChangePasswordView.as_view(), name="change-password"),
    path("user/", CurrentUserView.as_view(), name="user-me"),
    path("wallet/", WalletDetailAPIView.as_view(), name="wallet-me"),
    path("asset/", MyAssetView.as_view(), name="my-assets"),
    path(
        "transaction/",
        UserTransactions.as_view(),
        name="user-transactions",
    ),
    path("buy/", BuyCoinAPIView.as_view(), name="buy-coin"),
    path("sell/", SellAssetAPIView.as_view(), name="sell-asset"),
    path("swap/", SwapView.as_view(), name="swap"),
]
