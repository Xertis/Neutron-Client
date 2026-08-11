local inventory_manager = import "core/inventory"

input.add_callback("player.pick", inventory_manager.pick)
