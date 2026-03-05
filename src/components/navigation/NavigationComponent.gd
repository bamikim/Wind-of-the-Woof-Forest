class_name NavigationComponent
extends BaseComponent

## 아이소메트릭 그리드 상에서의 경로 탐색 및 이동을 처리하는 컴포넌트입니다.

@export var speed: float = 150.0

var _target_position: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var is_moving: bool:
	get: return _is_moving

var _navigation_agent: NavigationAgent2D
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# NavigationAgent2D 생성 및 설정
	_navigation_agent = NavigationAgent2D.new()
	_navigation_agent.path_desired_distance = 4.0
	_navigation_agent.target_desired_distance = 4.0
	
	# 부모(BaseDog 등)가 Node2D일 때만 정상 작동하므로 부모에 추가
	call_deferred("_add_agent_to_owner")

func _add_agent_to_owner() -> void:
	if owner_entity:
		owner_entity.add_child(_navigation_agent)
		_target_position = owner_entity.global_position
	else:
		# 소유주가 아직 없으면 직접 추가 (에러 방지용)
		add_child(_navigation_agent)

func _on_owner_set() -> void:
	if _navigation_agent.get_parent():
		_navigation_agent.get_parent().remove_child(_navigation_agent)
	
	if owner_entity:
		owner_entity.add_child(_navigation_agent)

func _physics_process(delta: float) -> void:
	if not _is_moving or not owner_entity or not _navigation_agent.is_inside_tree():
		return
		
	if _navigation_agent.is_navigation_finished():
		_is_moving = false
		velocity = Vector2.ZERO
		return
		
	var next_path_position: Vector2 = _navigation_agent.get_next_path_position()
	var current_agent_position: Vector2 = owner_entity.global_position
	velocity = (next_path_position - current_agent_position).normalized() * speed
	
	owner_entity.global_position += velocity * delta
	
	# 이동 방향에 따라 스프라이트 반전 등 연출 추가 가능

func move_to(target_pos: Vector2) -> void:
	if not _navigation_agent.is_inside_tree():
		return
		
	_target_position = target_pos
	_navigation_agent.target_position = target_pos
	_is_moving = true
