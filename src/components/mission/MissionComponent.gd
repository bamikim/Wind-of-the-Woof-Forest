class_name MissionComponent
extends BaseComponent

## 엔티티의 미션 상태와 타이머를 관리하는 컴포넌트입니다.

signal mission_started(mission: MissionResource)
signal mission_completed(mission: MissionResource)
signal reward_claimed(amount: int)

enum MissionState {IDLE, IN_PROGRESS, COMPLETED}

var current_state: MissionState = MissionState.IDLE
var current_mission: MissionResource = null
var remaining_time: float = 0.0

var bonus_amount: int = 0
var bonus_xp: int = 0
var extra_chance_multi: float = 1.0
var worker_name: String = ""
var worker_personality: int = 0
var worker_job: int = 0
var worker_dog_ref: Node2D = null

func _physics_process(delta: float) -> void:
	if current_state == MissionState.IN_PROGRESS:
		remaining_time -= delta
		if remaining_time <= 0:
			complete_mission()

func start_mission(mission: MissionResource, worker_dog = null) -> void:
	current_mission = mission
	remaining_time = mission.duration_seconds
	current_state = MissionState.IN_PROGRESS
	worker_dog_ref = worker_dog
	
	bonus_amount = 0
	bonus_xp = 0
	extra_chance_multi = 1.0
	worker_name = ""
	worker_personality = 0
	worker_job = 0
	
	if worker_dog and worker_dog.has_method("get_dog_data") and owner_entity and owner_entity.get("building_data"):
		var dog_res = worker_dog.dog_data
		var build_res = owner_entity.building_data
		if dog_res and build_res:
			worker_name = dog_res.dog_name
			worker_personality = dog_res.personality
			worker_job = dog_res.job
			
			# 1. 직업 일치 보너스 (보상 20% 증가)
			if dog_res.job != 0 and dog_res.job == build_res.recommended_job:
				bonus_amount = int(mission.reward_amount * 0.2)
				bonus_xp = int(mission.reward_xp * 0.2)
				print_debug("[MissionComponent] Job matched! Bonus applied.")
				
			# 2. 성격 보너스
			if dog_res.personality == 1: # ENERGETIC (활발함) -> 시간 15% 단축
				remaining_time *= 0.85
			elif dog_res.personality == 2: # METICULOUS (꼼꼼함) -> 희귀 보상 확률 증가
				extra_chance_multi = 1.5
			elif dog_res.personality == 3: # LAZY (게으름) -> 시간 10% 증가, XP 소폭 증가
				remaining_time *= 1.1
				bonus_xp += int(mission.reward_xp * 0.1)
				
	mission_started.emit(mission)
	print_debug("[MissionComponent] Mission started: ", mission.mission_name)

func complete_mission() -> void:
	current_state = MissionState.COMPLETED
	remaining_time = 0
	mission_completed.emit(current_mission)
	print_debug("[MissionComponent] Mission completed: ", current_mission.mission_name)

func claim_reward() -> void:
	if current_state == MissionState.COMPLETED:
		var amount = current_mission.reward_amount + bonus_amount
		var xp = current_mission.reward_xp + bonus_xp
		
		# 보상 비행 연출 요청 (현재 오너 건물의 위치 사용)
		var spawn_pos = Vector2.ZERO
		if owner_entity:
			spawn_pos = owner_entity.global_position + Vector2(0, -50)
		
		if amount > 0:
			UIManager.spawn_flying_reward_requested.emit("treats", amount, spawn_pos)
			GameManager.dog_treats += amount
			
		if xp > 0:
			UIManager.spawn_flying_reward_requested.emit("xp", xp, spawn_pos)
			GameManager.add_xp(xp)
			
		if current_mission.reward_material_type != "" and current_mission.reward_material_amount > 0:
			GameManager.add_material(current_mission.reward_material_type, current_mission.reward_material_amount)
			# 플라잉 아이콘 미지원일 경우 나중에 구현할 수 있습니다. 여기서는 우선 직접 증가만 시킵니다.
		
		# 추가 확률 보상 처리
		if current_mission.extra_reward_id != "" and current_mission.extra_reward_chance > 0:
			var final_chance = current_mission.extra_reward_chance * extra_chance_multi
			if randf() < final_chance:
				if current_mission.extra_reward_id == "cookie":
					GameManager.cookies += 1
					UIManager.spawn_flying_reward_requested.emit("cookie", 1, spawn_pos)
				else:
					InventoryManager.add_item(current_mission.extra_reward_id, 1)
				print_debug("[MissionComponent] Extra reward claimed: ", current_mission.extra_reward_id)
		
		reward_claimed.emit(amount)
		
		# 상태 초기화
		current_state = MissionState.IDLE
		current_mission = null
		print_debug("[MissionComponent] Reward claimed: ", amount)
