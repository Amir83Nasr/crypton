from django.contrib import admin

from .models import (
    CustomUser,
    Wallet,
    Coin,
    Asset,
    Announcement,
    ContactMessage,
    Transaction,
)


admin.site.register(CustomUser)
admin.site.register(Coin)
admin.site.register(Wallet)
admin.site.register(Asset)
admin.site.register(Transaction)

admin.site.register(Announcement)
admin.site.register(ContactMessage)
