extends Node

## 게임 데이터를 로컬 파일로 저장하고 불러오는 기능을 담당합니다.
## 저장 대상: 재화, 레벨/XP, 인벤토리, 구매 이력

const SAVE_PATH = "user://save_game.json"
const SAVE_VERSION = 2 # 저장 포맷 버전

func save_game() -> void:
	## 현재 게임 상태를 JSON 파일로 로컬 저장합니다.
	var save_data = {
		"version": SAVE_VERSION,
		"dog_treats": GameManager.dog_treats,
		"forest_harmony_level": GameManager.forest_harmony_level,
		"current_xp": GameManager.current_xp,
		"inventory": GameManager.inventory,
		"purchased_items": GameManager.purchased_items,
		"last_save_time": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		print_debug("[SaveManager] Game saved. Treats: %d, Items: %d" % [GameManager.dog_treats, GameManager.inventory.size()])
	else:
		push_error("[SaveManager] Could not open save file for writing!")
	
	# Firestore 연동 시 여기서 API 호출을 수행합니다.

func load_game() -> void:
	## 로컬 저장 파일에서 게임 데이터를 불러옵니다.
	if not FileAccess.file_exists(SAVE_PATH):
		print_debug("[SaveManager] No save file found. Starting fresh.")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Could not open save file for reading!")
		return
	
	var json_string = file.get_as_text()
	var json = JSON.parse_string(json_string)
	
	if not json:
		push_error("[SaveManager] Failed to parse save file! Corrupted data?")
		return
	
	# 버전 체크 (하위 호환성)
	var version = json.get("version", 1)
	print_debug("[SaveManager] Loading save file v%d..." % version)
	
	GameManager.dog_treats = json.get("dog_treats", 500)
	GameManager.forest_harmony_level = json.get("forest_harmony_level", 1)
	GameManager.current_xp = json.get("current_xp", 0)
	
	# 인벤토리 불러오기
	var saved_inventory: Variant = json.get("inventory", {})
	if saved_inventory is Dictionary:
		GameManager.inventory = saved_inventory
	
	# 구매 이력 불러오기 (v2 이상)
	if version >= 2:
		var saved_purchased: Variant = json.get("purchased_items", [])
		if saved_purchased is Array:
			GameManager.purchased_items.clear()
			for item_id in saved_purchased:
				GameManager.purchased_items.append(str(item_id))
	
	print_debug("[SaveManager] Load complete. Treats: %d, Purchased: %s" % [GameManager.dog_treats, str(GameManager.purchased_items)])

func delete_save() -> void:
	## 저장 파일을 삭제합니다 (게임 초기화 시 사용).
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print_debug("[SaveManager] Save file deleted.")

func has_save() -> bool:
	## 저장 파일이 존재하는지 확인합니다.
	return FileAccess.file_exists(SAVE_PATH)
