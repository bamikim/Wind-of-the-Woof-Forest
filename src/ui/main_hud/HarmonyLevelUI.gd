extends Control

## 조화도(레벨)와經驗值(XP)를 표시하는 HUD 스크립트입니다.

@onready var level_label: Label = $HBoxContainer/LevelLabel
@onready var xp_bar: TextureProgressBar = $HBoxContainer/XPBar
@onready var treats_label: Label = $TreatsContainer/TreatsLabel

@onready var shop_button: Button = $MenuButtons/ShopButton
@onready var bag_button: Button = $MenuButtons/BagButton
@onready var edit_mode_button: Button = $MenuButtons/EditModeButton
@onready var shop_ui: Control = $ShopUI
@onready var bag_ui: Control = $BagUI

func _ready() -> void:
	# 전체화면 UI가 클릭 이벤트를 삼키지 않도록 설정
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 시그널 연결
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.open_shop_requested.connect(shop_ui.show)
	
	# UI 버튼 연결
	shop_button.pressed.connect(shop_ui.show)
	bag_button.pressed.connect(bag_ui.open_bag)
	edit_mode_button.pressed.connect(_on_edit_mode_pressed)
	GameManager.edit_mode_toggled.connect(_on_edit_mode_toggled)
	
	# 상점 오픈 시 자동으로 일반 모드로 변경 (에러 방지용)
	shop_ui.visibility_changed.connect(func(): if shop_ui.visible: GameManager.is_edit_mode = false)
	
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

func _on_edit_mode_pressed() -> void:
	GameManager.is_edit_mode = not GameManager.is_edit_mode

func _on_edit_mode_toggled(is_active: bool) -> void:
	if is_active:
		edit_mode_button.text = "일반 모드로"
		edit_mode_button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4)) # 붉은색 활성화 피드백
		print_debug("[HarmonyLevelUI] Edit Mode: ON")
	else:
		edit_mode_button.text = "배치 모드로"
		edit_mode_button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		print_debug("[HarmonyLevelUI] Edit Mode: OFF")
