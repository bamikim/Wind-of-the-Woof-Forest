extends Node

## 게임 전역 상태(재화, 레벨 등)를 관리하는 싱글톤 클래스.

signal currency_changed(new_amount: int)
signal level_changed(new_level: int)
signal xp_changed(current_xp: int, max_xp: int)
signal inventory_changed(item_id: String, amount: int)
signal start_build_mode(res: Resource, cost: int, source: String)
signal open_shop_requested
signal edit_mode_toggled(is_active: bool)

var is_edit_mode: bool = false:
	set(value):
		is_edit_mode = value
		edit_mode_toggled.emit(is_edit_mode)

var inventory: Dictionary = {}
var purchased_items: Array[String] = []

var dog_treats: int = 1500:
	set(value):
		dog_treats = value
		currency_changed.emit(dog_treats)

var forest_harmony_level: int = 1:
	set(value):
		forest_harmony_level = value
		level_changed.emit(forest_harmony_level)

var current_xp: int = 0:
	set(value):
		current_xp = value
		_check_level_up()
		xp_changed.emit(current_xp, get_max_xp())

func add_xp(amount: int) -> void:
	current_xp += amount
	print_debug("[GameManager] XP Added: ", amount, " Current: ", current_xp)

func get_max_xp() -> int:
	# 레벨별 필요 경험치 공식 (예: 레벨 * 100)
	return forest_harmony_level * 100

func add_item(item_id: String, amount: int = 1) -> void:
	if not inventory.has(item_id):
		inventory[item_id] = 0
	inventory[item_id] += amount
	inventory_changed.emit(item_id, inventory[item_id])
	print_debug("[GameManager] Item Added: ", item_id, " Amount: ", amount, " Total: ", inventory[item_id])

func remove_item(item_id: String, amount: int = 1) -> bool:
	if has_item(item_id) and inventory[item_id] >= amount:
		inventory[item_id] -= amount
		inventory_changed.emit(item_id, inventory[item_id])
		print_debug("[GameManager] Item Removed: ", item_id, " Amount: ", amount, " Left: ", inventory[item_id])
		return true
	return false

func has_item(item_id: String) -> bool:
	return inventory.has(item_id) and inventory[item_id] > 0

func mark_as_purchased(item_id: String) -> void:
	if not purchased_items.has(item_id):
		purchased_items.append(item_id)
		print_debug("[GameManager] Marked as purchased: ", item_id)

func has_purchased(item_id: String) -> bool:
	return purchased_items.has(item_id)

func deduct_treats(cost: int) -> bool:
	if dog_treats >= cost:
		dog_treats -= cost
		return true
	print_debug("[GameManager] Not enough treats! Cost: ", cost)
	return false

func _check_level_up() -> void:
	var max_xp = get_max_xp()
	while current_xp >= max_xp:
		current_xp -= max_xp
		forest_harmony_level += 1
		max_xp = get_max_xp()
		print_debug("[GameManager] Level Up! Now Level: ", forest_harmony_level)

func _ready() -> void:
	print_debug("[GameManager] Managed systems initialized.")
	# 게임 시작 시 저장 블러오기 (다음 프레임에 실행하여 씸 이받기 보장)
	call_deferred("_autoload_save")

func _autoload_save() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		print_debug("[GameManager] Fresh start - no save file.")

func _notification(what: int) -> void:
	# 앱이 종료될 때 자동 저장
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		SaveManager.save_game()
		print_debug("[GameManager] Auto-saved on exit.")
