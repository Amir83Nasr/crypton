import json
from decimal import Decimal
from django.core.management.base import BaseCommand
from core.models import Coin


class Command(BaseCommand):
    help = "Import coins from a JSON file to the database"

    def add_arguments(self, parser):
        parser.add_argument(
            "json_file", type=str, help="Path to the JSON file containing coins data"
        )

    def handle(self, *args, **kwargs):
        json_file = kwargs["json_file"]

        try:
            with open(json_file, "r") as file:
                coins_data = json.load(file)
        except Exception as e:
            self.stderr.write(self.style.ERROR(f"Error reading JSON file: {e}"))
            return

        for coin in coins_data:
            obj, created = Coin.objects.update_or_create(
                symbol=coin["symbol"],
                defaults={
                    "name": coin["name"],
                    "image": coin["image"],
                    "current_price": Decimal(coin["current_price"]),
                    "market_cap": coin["market_cap"],
                    "total_volume": coin["total_volume"],
                    "market_cap_rank": coin["market_cap_rank"],
                    "ath": Decimal(coin["ath"]),
                    "atl": Decimal(coin["atl"]),
                    "is_active": True,
                },
            )
            action = "Created" if created else "Updated"
            self.stdout.write(self.style.SUCCESS(f"{action} coin: {obj.symbol}"))

        self.stdout.write(self.style.SUCCESS("Import complete!"))
