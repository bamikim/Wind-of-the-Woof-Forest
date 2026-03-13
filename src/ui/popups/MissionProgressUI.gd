extends Control

## 미션 진행 상황을 보여주는 팝업입니다.

signal cancel_requested

@onready var mission_label: Label = $Panel/VBoxContainer/MissionLabel
@onready var time_label: Label = $Panel/VBoxContainer/TimeLabel
@onready var progress_bar: ProgressBar = $Panel/VBoxContainer/ProgressBar
@onready var cancel_btn: Button = $Panel/VBoxContainer/CancelBtn
@onready var fast_complete_btn: Button = $Panel/VBoxContainer/FastCompleteBtn
@onready var close_button: Button = $Panel/CloseButton

var _mission_comp: MissionComponent = null

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	fast_complete_btn.pressed.connect(_on_fast_complete_pressed)
	set_process(true)

func setup(mission_comp: MissionComponent, dog_name: String) -> void:
	_mission_comp = mission_comp
	mission_label.text = "%s(이)가\n%s 수행 중" % [dog_name, _mission_comp.current_mission.mission_name]
	progress_bar.max_value = _mission_comp.current_mission.duration_seconds
	_update_ui()

func _process(_delta: float) -> void:
	if not _mission_comp or not is_inside_tree():
		return
		
	# 완료되었으면 자동으로 닫힘
	if _mission_comp.current_state == MissionComponent.MissionState.COMPLETED:
		queue_free()
		return
		
	_update_ui()

func _update_ui() -> void:
	if not _mission_comp.current_mission: return
	
	var remain = _mission_comp.remaining_time
	progress_bar.value = _mission_comp.current_mission.duration_seconds - remain
	
	var mins = floor(remain / 60.0)
	var secs = fmod(remain, 60.0)
	time_label.text = "%02d:%02d 남음" % [int(mins), int(secs)]
	
	# 남은 시간에 따라 필요한 쿠키 수 계산 (10분당 1개, 올림)
	var required_cookies = ceil(remain / 600.0)
	fast_complete_btn.text = "🍪 %d개로 즉시 완료하기" % required_cookies

func _on_fast_complete_pressed() -> void:
	if not _mission_comp or not _mission_comp.current_mission: return
	
	var remain = _mission_comp.remaining_time
	if remain <= 0: return
	
	var required_cookies = ceil(remain / 600.0)
	if GameManager.cookies >= required_cookies:
		GameManager.cookies -= required_cookies
		UIManager.show_toast("쿠키 %d개를 사용하여 즉시 완료했습니다!" % required_cookies)
		_mission_comp.complete_mission()
		queue_free()
	else:
		UIManager.show_toast("쿠키가 부족합니다! (필요: %d개)" % required_cookies)

func _on_cancel_pressed() -> void:
	cancel_requested.emit()
	queue_free()
