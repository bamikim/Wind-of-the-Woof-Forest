extends Node

## 게임 데이터를 로컬 파일로 저장하고 불러오는 기능을 담당합니다.
## 저장 대상: 재화, 레벨/XP, 인벤토리, 구매 이력

const SAVE_PATH = "user://save_game.json"
const SAVE_VERSION = 2 # 저장 포맷 버전

func save_game() -> void:
	## 현재 게임 상태를 JSON 파일로 로컬 저장합니다.
	# 현재 배치된 건물 목록은 씬 트리가 살아있을 때만 읽어옵니다 (앱 종료/에디터 Stop 시 null 방지)
	if is_inside_tree() and get_tree() and get_tree().current_scene:
		var current_placed = []
		for node in get_tree().get_nodes_in_group("buildings"):
			if node is BaseBuilding and node.building_data:
				var m_state = 0
				var m_id = ""
				var m_time = 0.0
				var m_b_amt = 0
				var m_b_xp = 0
				var m_e_multi = 1.0
				var m_w_name = ""
				var m_w_per = 0
				var m_w_job = 0
				if node.mission_component:
					m_state = node.mission_component.current_state
					if node.mission_component.current_mission:
						m_id = node.mission_component.current_mission.resource_path # resource path for easy loading
					m_time = node.mission_component.remaining_time
					m_b_amt = node.mission_component.bonus_amount
					m_b_xp = node.mission_component.bonus_xp
					m_e_multi = node.mission_component.extra_chance_multi
					m_w_name = node.mission_component.worker_name
					m_w_per = node.mission_component.worker_personality
					m_w_job = node.mission_component.worker_job
					
				current_placed.append({
					"path": node.building_data.resource_path,
					"pos_x": node.global_position.x,
					"pos_y": node.global_position.y,
					"flip_h": node.sprite.flip_h,
					"m_state": m_state,
					"m_id": m_id,
					"m_time": m_time,
					"m_b_amt": m_b_amt,
					"m_b_xp": m_b_xp,
					"m_e_multi": m_e_multi,
					"m_w_name": m_w_name,
					"m_w_per": m_w_per,
					"m_w_job": m_w_job
				})
		InventoryManager.placed_buildings = current_placed

	var exp_data_list = []
	for exp_item in ExplorationManager.active_explorations:
		if exp_item.mission and exp_item.dog:
			var m_id = exp_item.mission.resource_path # Or mission_id if set
			# Use dog_id instead of dog_id if one exists, else use name
			var d_name = exp_item.dog.entity_name
			exp_data_list.append({
				"m_id": m_id,
				"d_name": d_name,
				"time_left": exp_item.time_left
			})

	var save_data = {
		"version": SAVE_VERSION,
		"dog_treats": GameManager.dog_treats,
		"cookies": GameManager.cookies,
		"materials": GameManager.materials,
		"forest_harmony_level": GameManager.forest_harmony_level,
		"current_xp": GameManager.current_xp,
		"inventory": InventoryManager.inventory,
		"purchased_items": InventoryManager.purchased_items,
		"placed_buildings": InventoryManager.placed_buildings,
		"active_explorations": exp_data_list,
		"last_save_time": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		print_debug("[SaveManager] Game saved. Treats: %d, Items: %d" % [GameManager.dog_treats, InventoryManager.inventory.size()])
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
	
	GameManager.dog_treats = json.get("dog_treats", 10000)
	GameManager.cookies = json.get("cookies", 0)
	
	if json.has("materials"):
		var saved_mats = json.get("materials", {})
		for key in saved_mats.keys():
			GameManager.materials[key] = int(saved_mats[key])
			
	GameManager.forest_harmony_level = json.get("forest_harmony_level", 1)
	GameManager.current_xp = json.get("current_xp", 0)
	
	# 인벤토리 불러오기
	var saved_inventory: Variant = json.get("inventory", {})
	if saved_inventory is Dictionary:
		InventoryManager.inventory = saved_inventory
	
	# 구매 이력 불러오기 (v2 이상)
	if version >= 2:
		var saved_purchased: Variant = json.get("purchased_items", [])
		if saved_purchased is Array:
			InventoryManager.purchased_items.clear()
			for item_id in saved_purchased:
				InventoryManager.purchased_items.append(str(item_id))
				
	# 오프라인 시간 계산 및 배치된 건물 불러오기
	var last_save_time = json.get("last_save_time", Time.get_unix_time_from_system())
	var current_time = Time.get_unix_time_from_system()
	var offline_seconds = max(0, current_time - last_save_time)
	print_debug("[SaveManager] Offline time: %d seconds." % offline_seconds)
	
	# 오프라인 미션 완료 결과 버퍼 (나중에 OfflineJournalUI에서 읽도록 GameManager 등에 둘 수도 있지만, 
	# 일단 InventoryManager나 GameManager에 배열로 담아둡니다)
	GameManager.set_meta("offline_completed_missions", [])
	var completed_missions = []
	
	var saved_buildings: Variant = json.get("placed_buildings", [])
	if saved_buildings is Array:
		# Process offline time for buildings
		var processed_buildings = []
		for b in saved_buildings:
			if typeof(b) == TYPE_DICTIONARY:
				var m_state = b.get("m_state", 0)
				var m_time = b.get("m_time", 0.0)
				
				if m_state == 2: # 이미 완료된 상태로 저장되었던 미션
					completed_missions.append({
						"m_id": b.get("m_id", ""),
						"worker_name": b.get("m_w_name", ""),
						"worker_personality": b.get("m_w_per", 0),
						"worker_job": b.get("m_w_job", 0),
						"m_b_amt": b.get("m_b_amt", 0),
						"m_b_xp": b.get("m_b_xp", 0)
					})
					m_state = 0
					m_time = 0.0
				elif m_state == 1: # 진행 중이었던 미션
					m_time -= offline_seconds
					if m_time <= 0:
						m_state = 0 # 완료 처리: IDLE로 초기화하고 보상은 일지로 넘김
						m_time = 0.0
						completed_missions.append({
							"m_id": b.get("m_id", ""),
							"worker_name": b.get("m_w_name", ""),
							"worker_personality": b.get("m_w_per", 0),
							"worker_job": b.get("m_w_job", 0),
							"m_b_amt": b.get("m_b_amt", 0),
							"m_b_xp": b.get("m_b_xp", 0)
						})
						
				b["m_state"] = m_state
				b["m_time"] = m_time
				processed_buildings.append(b)
				
		InventoryManager.placed_buildings = processed_buildings
	
	# 오프라인 동안 완료된 탐험 처리
	var saved_explorations: Variant = json.get("active_explorations", [])
	if saved_explorations is Array:
		for exp_dict in saved_explorations:
			if typeof(exp_dict) == TYPE_DICTIONARY:
				var m_id = exp_dict.get("m_id", "")
				var d_name = exp_dict.get("d_name", "")
				var t_left = exp_dict.get("time_left", 0.0)
				t_left -= offline_seconds
				
				# 완료되었다면 버퍼에 추가 (나중에 UI 로드 전용으로 사용할 수 있도록 GameManager 메타에)
				# TODO: 이 예시에서는 ExplorationManager가 저장된 미션을 다시 실행시키는 구조로 구현합니다.
				# 지금은 기초 형태로서 단순히 오프라인 완료 시 GameManager의 버퍼에 일반 미션처럼 추가해둡니다.
				if t_left <= 0:
					# 미션 리소스를 다시 로드하여 보상 확인
					var res = load(m_id) as MissionResource
					if res:
						completed_missions.append({
							"m_id": m_id,
							"worker_name": d_name,
							"worker_personality": 0,
							"worker_job": 0,
							"m_b_amt": 0,
							"m_b_xp": 0
						})
						# 임시로 재료도 바로 여기서 지급해버립니다 (오프라인 수령)
						if res.reward_material_type != "" and res.reward_material_amount > 0:
							GameManager.add_material(res.reward_material_type, res.reward_material_amount)
				else:
					# 나중에 StartingForest에서 강아지가 로드되었을 때 다시 ExplorationManager에 위임
					GameManager.set_meta("pending_explorations", GameManager.get_meta("pending_explorations", []) + [ {
						"m_id": m_id,
						"d_name": d_name,
						"time_left": t_left
					}])
					
	GameManager.set_meta("offline_completed_missions", completed_missions)
		
	print_debug("[SaveManager] Load complete. Treats: %d, Purchased: %s" % [GameManager.dog_treats, str(InventoryManager.purchased_items)])
	# 게임 불러오기 시그널 발생 (StartingForest에서 이 시그널을 듣고 맵에 건물을 배치)
	GameManager.game_loaded.emit()

func delete_save() -> void:
	## 저장 파일을 삭제합니다 (게임 초기화 시 사용).
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print_debug("[SaveManager] Save file deleted.")

func has_save() -> bool:
	## 저장 파일이 존재하는지 확인합니다.
	return FileAccess.file_exists(SAVE_PATH)
