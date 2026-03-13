extends Node

## 게임 전역 상태(재화, 레벨 등)를 관리하는 싱글톤 클래스.

signal currency_changed(new_amount: int)
signal cookies_changed(new_amount: int)
signal level_changed(new_level: int)
signal xp_changed(current_xp: int, max_xp: int)
signal materials_changed(material_type: String, new_amount: int)

@warning_ignore("unused_signal")
signal game_loaded


var dog_treats: int = 10000:
	set(value):
		dog_treats = value
		currency_changed.emit(dog_treats)

var cookies: int = 0:
	set(value):
		cookies = value
		cookies_changed.emit(cookies)

# 탐험으로 얻는 특수 재료들 (wood, stone, dew 등)
var materials: Dictionary = {
	"wood": 0,
	"stone": 0,
	"dew": 0
}

func add_material(type: String, amount: int) -> void:
	if materials.has(type):
		materials[type] += amount
		materials_changed.emit(type, materials[type])
		print_debug("[GameManager] Material Added: %s x%d (Total: %d)" % [type, amount, materials[type]])

func remove_material(type: String, amount: int) -> bool:
	if materials.has(type) and materials[type] >= amount:
		materials[type] -= amount
		materials_changed.emit(type, materials[type])
		return true
	print_debug("[GameManager] Not enough material: ", type)
	return false

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
		# 저장 파일이 없을 때 최초 실행용 game_loaded 호출
		game_loaded.emit()

func _notification(what: int) -> void:
	# 앱이 종료될 때 자동 저장
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		SaveManager.save_game()
		print_debug("[GameManager] Auto-saved on exit.")
