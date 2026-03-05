extends Control

## 조화도(레벨)와經驗值(XP)를 표시하는 HUD 스크립트입니다.

@onready var level_label: Label = $HBoxContainer/LevelLabel
@onready var xp_bar: TextureProgressBar = $HBoxContainer/XPBar
@onready var treats_label: Label = $TreatsContainer/TreatsLabel

func _ready() -> void:
	# 시그널 연결
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.currency_changed.connect(_on_currency_changed)
	
	# 초기 값 설정
	_on_level_changed(GameManager.forest_harmony_level)
	_on_xp_changed(GameManager.current_xp, GameManager.get_max_xp())
	_on_currency_changed(GameManager.dog_treats)

func _on_level_changed(new_level: int) -> void:
	level_label.text = "Lv. %d" % new_level

func _on_xp_changed(current_xp: int, max_xp: int) -> void:
	xp_bar.max_value = max_xp
	xp_bar.value = current_xp

func _on_currency_changed(new_amount: int) -> void:
	treats_label.text = str(new_amount)
