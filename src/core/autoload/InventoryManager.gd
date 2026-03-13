extends Node

## 인벤토리(가방), 상점 구매 이력, 필드에 배치된 건물 데이터의 소유권을 관리하는 싱글톤입니다.

signal inventory_changed(item_id: String, amount: int)

var inventory: Dictionary = {}
var purchased_items: Array[String] = []
var placed_buildings: Array = []

func add_item(item_id: String, amount: int = 1) -> void:
	if not inventory.has(item_id):
		inventory[item_id] = 0
	inventory[item_id] += amount
	inventory_changed.emit(item_id, inventory[item_id])
	print_debug("[InventoryManager] Item Added: ", item_id, " Amount: ", amount, " Total: ", inventory[item_id])

func remove_item(item_id: String, amount: int = 1) -> bool:
	if has_item(item_id) and inventory[item_id] >= amount:
		inventory[item_id] -= amount
		inventory_changed.emit(item_id, inventory[item_id])
		print_debug("[InventoryManager] Item Removed: ", item_id, " Amount: ", amount, " Left: ", inventory[item_id])
		return true
	return false

func has_item(item_id: String) -> bool:
	return inventory.has(item_id) and inventory[item_id] > 0

func mark_as_purchased(item_id: String) -> void:
	if not purchased_items.has(item_id):
		purchased_items.append(item_id)
		print_debug("[InventoryManager] Marked as purchased: ", item_id)

func has_purchased(item_id: String) -> bool:
	return purchased_items.has(item_id)
