extends Control

## 조화도(레벨)와經驗值(XP)를 표시하는 HUD 스크립트입니다.

@onready var level_label: Label = $TopPanel/HBoxContainer/LevelLabel
@onready var xp_bar: ProgressBar = $TopPanel/HBoxContainer/XPBar
@onready var treats_label: Label = $TreatsContainer/TreatsLabel
@onready var cookies_label: Label = $CookiesContainer/CookiesLabel

@onready var wood_label: Label = $MaterialsContainer/WoodBox/Label
@onready var stone_label: Label = $MaterialsContainer/StoneBox/Label
@onready var dew_label: Label = $MaterialsContainer/DewBox/Label

@onready var shop_button: Button = $MenuButtons/ShopButton
@onready var map_button: Button = $MenuButtons/MapButton
@onready var bag_button: Button = $MenuButtons/BagButton
@onready var edit_mode_button: Button = $MenuButtons/EditModeButton

@onready var exploration_map_ui: Control = $ExplorationMapUI
@onready var shop_ui: Control = $ShopUI
@onready var bag_ui: Control = $BagUI

func _ready() -> void:
	# 전체화면 UI가 클릭 이벤트를 삼키지 않도록 설정
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 시그널 연결
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.cookies_changed.connect(_on_cookies_changed)
	GameManager.materials_changed.connect(_on_materials_changed)
	UIManager.open_shop_requested.connect(shop_ui.show)
	UIManager.spawn_flying_reward_requested.connect(_on_spawn_flying_reward_requested)
	
	# UI 버튼 연결
	shop_button.pressed.connect(shop_ui.show)
	map_button.pressed.connect(exploration_map_ui.show)
	bag_button.pressed.connect(bag_ui.open_bag)
	edit_mode_button.pressed.connect(_on_edit_mode_button_pressed) # 배치 모드 연동
	UIManager.edit_mode_toggled.connect(_on_edit_mode_toggled)
	
	# 상점 오픈 시 자동으로 일반 모드로 변경 (에러 방지용)
	shop_ui.visibility_changed.connect(func(): if shop_ui.visible: UIManager.is_edit_mode = false)
	
	# 초기 값 설정
	_on_level_changed(GameManager.forest_harmony_level)
	_on_xp_changed(GameManager.current_xp, GameManager.get_max_xp())
	_on_currency_changed(GameManager.dog_treats)
	_on_cookies_changed(GameManager.cookies)
	_on_materials_changed("wood", GameManager.materials.get("wood", 0))
	_on_materials_changed("stone", GameManager.materials.get("stone", 0))
	_on_materials_changed("dew", GameManager.materials.get("dew", 0))

func _on_materials_changed(type: String, amount: int) -> void:
	match type:
		"wood":
			if wood_label: wood_label.text = str(amount)
		"stone":
			if stone_label: stone_label.text = str(amount)
		"dew":
			if dew_label: dew_label.text = str(amount)

func _on_level_changed(new_level: int) -> void:
	level_label.text = "Lv. %d" % new_level

func _on_xp_changed(current_xp: int, max_xp: int) -> void:
	xp_bar.max_value = max_xp
	xp_bar.value = current_xp

func _on_currency_changed(new_amount: int) -> void:
	treats_label.text = str(new_amount)

func _on_cookies_changed(new_amount: int) -> void:
	cookies_label.text = str(new_amount)

func _on_edit_mode_button_pressed() -> void:
	UIManager.is_edit_mode = not UIManager.is_edit_mode

func _on_edit_mode_toggled(is_active: bool) -> void:
	if is_active:
		edit_mode_button.text = "일반 모드로"
		edit_mode_button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4)) # 붉은색 활성화 피드백
		print_debug("[HarmonyLevelUI] Edit Mode: ON")
	else:
		edit_mode_button.text = "배치 모드로"
		edit_mode_button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		print_debug("[HarmonyLevelUI] Edit Mode: OFF")

func _on_spawn_flying_reward_requested(reward_type: String, amount: int, start_global_pos: Vector2) -> void:
	if amount <= 0: return
	
	var target_pos = Vector2.ZERO
	var icon_text = "✨"
	
	match reward_type:
		"treats":
			target_pos = treats_label.global_position
			icon_text = "🦴"
		"cookie":
			target_pos = cookies_label.global_position
			icon_text = "🍪"
		"xp":
			target_pos = xp_bar.global_position + Vector2(xp_bar.size.x / 2, 0)
			icon_text = "⭐"
			
	# 월드 좌표를 화면(UI) 좌표로 변환
	var canvas_transform = get_viewport().canvas_transform
	var start_screen_pos = canvas_transform * start_global_pos
	
	var icon_scene = load("res://src/vfx/FlyingRewardIcon.tscn")
	var spawn_count = min(amount, 5) # 시각적 혼잡 방지를 위해 최대 5개만 스폰
	
	for i in range(spawn_count):
		var icon = icon_scene.instantiate()
		add_child(icon)
		icon.setup(icon_text, start_screen_pos, target_pos)
		
		# 약간의 시간차를 두고 스폰
		if i < spawn_count - 1:
			await get_tree().create_timer(0.05).timeout
