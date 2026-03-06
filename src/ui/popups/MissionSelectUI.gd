extends Control

## 미션 선택 창 스크립트입니다.

signal mission_selected(mission: MissionResource)

@onready var mission_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/MissionList
@onready var close_button: Button = $Panel/CloseButton

var available_missions: Array[MissionResource] = []

func _ready() -> void:
	close_button.pressed.connect(queue_free)

func setup(missions: Array[MissionResource]) -> void:
	available_missions = missions
	_refresh_list()

func _refresh_list() -> void:
	# 기존 목록 제거
	for child in mission_list.get_children():
		child.queue_free()
	
	# 새로운 목록 생성
	for mission in available_missions:
		var btn = Button.new()
		btn.text = "%s (%d초)" % [mission.mission_name, int(mission.duration_seconds)]
		btn.pressed.connect(_on_mission_btn_pressed.bind(mission))
		mission_list.add_child(btn)

	# 삭제: 가방 보관 버튼은 편집 모드 전용 BuildingEditUI 로 이동했습니다.

func _on_mission_btn_pressed(mission: MissionResource) -> void:
	mission_selected.emit(mission)
	queue_free()
