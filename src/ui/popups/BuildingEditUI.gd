extends Control

## 배치 모드에서 건물을 클릭했을 때 뜨는 편집기(이동/반전/보관) 스크립트입니다.

signal move_requested
signal flip_requested
signal store_requested

@onready var close_button: Button = $Panel/CloseButton
@onready var move_btn: Button = $Panel/VBoxContainer/MoveBtn
@onready var flip_btn: Button = $Panel/VBoxContainer/FlipBtn
@onready var store_btn: Button = $Panel/VBoxContainer/StoreBtn

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	
	move_btn.pressed.connect(_on_move_btn_pressed)
	flip_btn.pressed.connect(_on_flip_btn_pressed)
	store_btn.pressed.connect(_on_store_btn_pressed)

func _on_move_btn_pressed() -> void:
	move_requested.emit()
	queue_free()

func _on_flip_btn_pressed() -> void:
	flip_requested.emit()
	queue_free()

func _on_store_btn_pressed() -> void:
	store_requested.emit()
	queue_free()
