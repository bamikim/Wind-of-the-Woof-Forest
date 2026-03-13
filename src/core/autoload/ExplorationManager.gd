extends Node

## 맵 외부 탐험 시스템(미션, 보상 수령, 파견)을 관리하는 전역 싱글톤입니다.

signal exploration_started(mission_res: MissionResource, dog: BaseDog)
signal exploration_completed(mission_res: MissionResource, dog: BaseDog)

var active_explorations: Array = []

func start_exploration(mission_res: MissionResource, dog: BaseDog) -> void:
	if not mission_res or not dog: return
	
	active_explorations.append({
		"mission": mission_res,
		"dog": dog,
		"time_left": mission_res.duration_seconds
	})
	
	dog.hide()
	dog.set_process(false)
	dog.set_physics_process(false)
	dog.current_state = dog.DogState.WORKING
	
	exploration_started.emit(mission_res, dog)
	print_debug("[ExplorationManager] Dog ", dog.entity_name, " dispatched on ", mission_res.mission_name)

func _process(delta: float) -> void:
	for i in range(active_explorations.size() - 1, -1, -1):
		var exp_data = active_explorations[i]
		exp_data.time_left -= delta
		
		# 탐험 완료!
		if exp_data.time_left <= 0:
			_complete_exploration(exp_data, i)

func _complete_exploration(exp_data: Dictionary, index: int) -> void:
	var mission = exp_data.mission as MissionResource
	var dog = exp_data.dog as BaseDog
	
	active_explorations.remove_at(index)
	
	dog.show()
	dog.set_process(true)
	dog.set_physics_process(true)
	dog.set_wandering()
	
	var spawn_pos = dog.global_position + Vector2(0, -50)
	
	if mission.reward_amount > 0:
		UIManager.spawn_flying_reward_requested.emit("treats", mission.reward_amount, spawn_pos)
		GameManager.dog_treats += mission.reward_amount
		
	if mission.reward_xp > 0:
		UIManager.spawn_flying_reward_requested.emit("xp", mission.reward_xp, spawn_pos)
		GameManager.add_xp(mission.reward_xp)
		
	if mission.reward_material_type != "" and mission.reward_material_amount > 0:
		GameManager.add_material(mission.reward_material_type, mission.reward_material_amount)
	
	exploration_completed.emit(mission, dog)
	print_debug("[ExplorationManager] ", dog.entity_name, " returned from ", mission.mission_name)
