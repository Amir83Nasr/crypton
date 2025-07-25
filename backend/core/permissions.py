from rest_framework import permissions
from rest_framework.permissions import BasePermission


class IsActiveUser(permissions.BasePermission):
    """
    فقط کاربرانی که is_active=True هستند اجازه استفاده از API را دارند.
    """

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if not request.user.is_active:
            # پیام خطا به جای False ساده
            raise permissions.exceptions.PermissionDenied(
                "حساب شما مسدود شده است.")
        return True


class IsAdminOrSelf(BasePermission):
    """
    فقط ادمین یا خود کاربر اجازه دسترسی دارد
    """

    def has_object_permission(self, request, view, obj):
        return request.user.is_superuser or obj == request.user
