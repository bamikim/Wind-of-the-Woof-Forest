extends Node

## 전역적인 UI 상태 및 창 열림/닫힘 시그널을 관리하는 싱글톤입니다.

@warning_ignore("unused_signal")
signal open_shop_requested
@warning_ignore("unused_signal")
signal edit_mode_toggled(is_active: bool)
@warning_ignore("unused_signal")
signal spawn_flying_reward_requested(reward_type: String, amount: int, start_global_pos: Vector2)

var is_edit_mode: bool = false:
	set(value):
		is_edit_mode = value
		edit_mode_toggled.emit(is_edit_mode)

func emit_open_shop_requested() -> void:
	open_shop_requested.emit()

func show_toast(message: String) -> void:
	var toast_scene = load("res://src/ui/commons/ToastUI.tscn")
	if not toast_scene: return
	
	var toast = toast_scene.instantiate()
	var root = get_tree().root
	if root:
		# 현재 씬의 최상단이나 CanvasLayer에 어태치 (보통 root의 마지막 자식)
		toast.z_index = 4000
		
		# CanvasLayer를 하나 생성해서 띄웁니다 (UI 위에 확실히 보이게)
		var canvas = CanvasLayer.new()
		canvas.layer = 100
		canvas.add_child(toast)
		root.add_child(canvas)
		
		# Toast 삭제 시 CanvasLayer도 같이 삭제되도록 설정
		toast.tree_exited.connect(canvas.queue_free)
		
		# 화면 중앙 표시를 위해 세팅 (ToastUI 내부 기준)
		toast.show_message(message)
