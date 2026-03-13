class_name BaseDog
extends BaseEntity

## 모든 강아지 엔티티의 공통 로직을 담당합니다.

@export var dog_data: DogResource:
	set(value):
		dog_data = value
		if is_inside_tree():
			_apply_dog_data()

@onready var navigation_component: NavigationComponent = $NavigationComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _current_anim: String = ""
enum DogState {WANDERING, WORKING}
var current_state: DogState = DogState.WANDERING

var _target_object: Node2D = null
var _on_arrival_callback: Callable

var _wander_timer: Timer

func _ready() -> void:
	super._ready()
	add_to_group("dogs")
	
	_wander_timer = Timer.new()
	_wander_timer.wait_time = randf_range(3.0, 7.0)
	_wander_timer.autostart = true
	add_child(_wander_timer)
	_wander_timer.timeout.connect(_on_wander_timeout)
	
	if dog_data:
		_apply_dog_data()
		
	if navigation_component:
		navigation_component.navigation_finished.connect(_on_navigation_finished)
		
	print_debug("[BaseDog] %s is ready to explore!" % entity_name)

func _physics_process(_delta: float) -> void:
	_update_animation()

func _on_navigation_finished() -> void:
	if current_state == DogState.WORKING and _target_object:
		_on_reached_target()

func _update_animation() -> void:
	if not navigation_component: return
	
	var anim_to_play = "idle"
	if navigation_component.is_moving:
		anim_to_play = "walk"
	
	if _current_anim != anim_to_play:
		_current_anim = anim_to_play
		_play_dog_animation(anim_to_play)
	
	# 이동 방향에 따른 스프라이트 반전 (오른쪽으로 갈 때 flip)
	if navigation_component.velocity.x > 0.1:
		sprite.flip_h = true
	elif navigation_component.velocity.x < -0.1:
		sprite.flip_h = false

func _play_dog_animation(anim_name: String) -> void:
	if not dog_data: return
	
	if anim_name == "walk":
		if dog_data.walk_spritesheet:
			sprite.texture = dog_data.walk_spritesheet
		animation_player.play("walk")
	else:
		if dog_data.idle_spritesheet:
			sprite.texture = dog_data.idle_spritesheet
		animation_player.play("idle")

func _on_wander_timeout() -> void:
	if current_state != DogState.WANDERING:
		return
		
	# 주변 랜덤 위치로 이동. 건물 위치를 피해서 최대 5번 재시도합니다.
	var target_pos = global_position
	for _attempt in range(5):
		var random_offset = Vector2(randf_range(-300, 300), randf_range(-300, 300))
		var candidate = global_position + random_offset
		var too_close = false
		
		var buildings = get_tree().get_nodes_in_group("buildings")
		for building in buildings:
			if building.global_position.distance_to(candidate) < 120.0:
				too_close = true
				break
		
		if not too_close:
			target_pos = candidate
			break
	
	move_to(target_pos)
	
	# 다음 배회 시간 랜덤 설정
	_wander_timer.wait_time = randf_range(5.0, 10.0)

## 특정 오브젝트(건물 등)와 상호작용 지시
func interact_with(target: Node2D, callback: Callable) -> void:
	current_state = DogState.WORKING
	_target_object = target
	_on_arrival_callback = callback
	
	# 건물의 정확한 정면 위치를 가져옵니다.
	var target_pos = target.get_interaction_position() if target.has_method("get_interaction_position") else target.global_position + Vector2(0, 80)
	
	# 자율 이동 중단하고 목표로 이동
	move_to(target_pos)
	print_debug("[BaseDog] %s heading to %s for interaction! (Target Pos: %s)" % [entity_name, target.name, str(target_pos)])

## 강아지가 이미 해당 목표에 위치하여 작업 중인 상태로 강제 전환 (게임 로드 시 사용)
func force_working_at(target: Node2D) -> void:
	current_state = DogState.WORKING
	_target_object = target
	
	var target_pos = target.get_interaction_position() if target.has_method("get_interaction_position") else target.global_position + Vector2(0, 80)
	global_position = target_pos
	
	if navigation_component:
		navigation_component._is_moving = false
		navigation_component.velocity = Vector2.ZERO
	_update_animation()
	print_debug("[BaseDog] %s is instantly working at %s!" % [entity_name, target.name])

func _on_reached_target() -> void:
	if _on_arrival_callback.is_valid():
		_on_arrival_callback.call()
		_on_arrival_callback = Callable() # 1회용
	
	# 상호작용 후 다시 배회로 돌아가는 것은 상위 로직(미션 완료 등)에서 결정할 수도 있지만,
	# 여기서는 일단 멈춰있게 합니다. (WORKING 상태 유지)

func set_wandering() -> void:
	current_state = DogState.WANDERING
	_target_object = null

func _apply_dog_data() -> void:
	entity_name = dog_data.dog_name
	if dog_data.texture:
		sprite.texture = dog_data.texture
	if navigation_component:
		pass # 추후 성격 등에 따른 이동 속도 보정 기능 추가 가능

func move_to(target_pos: Vector2) -> void:
	if navigation_component:
		navigation_component.move_to(target_pos)
