extends Node

## 게임 전역 상태(재화, 레벨 등)를 관리하는 싱글톤 클래스.

signal currency_changed(new_amount: int)
signal level_changed(new_level: int)
signal xp_changed(current_xp: int, max_xp: int)

var dog_treats: int = 0:
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

func _check_level_up() -> void:
	var max_xp = get_max_xp()
	while current_xp >= max_xp:
		current_xp -= max_xp
		forest_harmony_level += 1
		max_xp = get_max_xp()
		print_debug("[GameManager] Level Up! Now Level: ", forest_harmony_level)

func _ready() -> void:
	print_debug("[GameManager] Managed systems initialized.")
