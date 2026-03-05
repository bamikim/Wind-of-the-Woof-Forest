extends Node

## 게임 데이터를 로컬 또는 서버(Firestore)에 저장하고 불러오는 기능을 담당합니다.

const SAVE_PATH = "user://save_game.json"

func save_game() -> void:
	var save_data = {
		"dog_treats": GameManager.dog_treats,
		"forest_harmony_level": GameManager.forest_harmony_level,
		"current_xp": GameManager.current_xp,
		"unlocked_plots": _get_unlocked_plots_data(),
		"buildings": _get_buildings_data(),
		"last_save_time": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		print_debug("[SaveManager] Game saved locally.")
	
	# Firestore 연동 시 여기서 API 호출을 수행합니다.

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print_debug("[SaveManager] No save file found.")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.parse_string(json_string)
		
		if json:
			GameManager.dog_treats = json.get("dog_treats", 0)
			GameManager.forest_harmony_level = json.get("forest_harmony_level", 1)
			GameManager.current_xp = json.get("current_xp", 0)
			print_debug("[SaveManager] Game loaded successfully.")

func _get_unlocked_plots_data() -> Array:
	# 씬 트리를 돌며 ExpansionPlot의 상태를 수집하는 로직 (추후 구현)
	return []

func _get_buildings_data() -> Array:
	# 배치된 건물의 종류와 위치 정보를 수집하는 로직 (추후 구현)
	return []
