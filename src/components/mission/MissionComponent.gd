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

func _physics_process(delta: float) -> void:
	if current_state == MissionState.IN_PROGRESS:
		remaining_time -= delta
		if remaining_time <= 0:
			complete_mission()

func start_mission(mission: MissionResource) -> void:
	current_mission = mission
	remaining_time = mission.duration_seconds
	current_state = MissionState.IN_PROGRESS
	mission_started.emit(mission)
	print_debug("[MissionComponent] Mission started: ", mission.mission_name)

func complete_mission() -> void:
	current_state = MissionState.COMPLETED
	remaining_time = 0
	mission_completed.emit(current_mission)
	print_debug("[MissionComponent] Mission completed: ", current_mission.mission_name)

func claim_reward() -> void:
	if current_state == MissionState.COMPLETED:
		var amount = current_mission.reward_amount
		var xp = current_mission.reward_xp
		
		GameManager.dog_treats += amount
		GameManager.add_xp(xp)
		
		reward_claimed.emit(amount)
		
		# 상태 초기화
		current_state = MissionState.IDLE
		current_mission = null
		print_debug("[MissionComponent] Reward claimed: ", amount)
