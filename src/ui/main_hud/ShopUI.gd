extends Control

## 상점 팝업 UI를 제어하는 스크립트입니다.

@onready var close_button: Button = $Panel/CloseButton
@onready var items_container: VBoxContainer = $Panel/MarginContainer/ScrollContainer/ItemsContainer

var shop_items: Array = [
	{"path": "res://data/buildings/mill.tres", "cost": 200},
	{"path": "res://data/buildings/pump.tres", "cost": 150},
	{"path": "res://data/buildings/postbox.tres", "cost": 100}
]

func _ready() -> void:
	close_button.pressed.connect(hide)
	visibility_changed.connect(_on_visibility_changed)
	hide() # 기본적으로 숨김

func _on_visibility_changed() -> void:
	if visible:
		_populate_shop()

func _populate_shop() -> void:
	# 기존 목록 삭제
	for child in items_container.get_children():
		child.queue_free()
		
	for item_data in shop_items:
		var res: BuildingResource = load(item_data.path) as BuildingResource
		if res and not GameManager.has_purchased(res.building_id):
			var item_row = _create_item_row(res, item_data.cost)
			items_container.add_child(item_row)

func _create_item_row(res: BuildingResource, cost: int) -> Control:
	var hbox = HBoxContainer.new()
	
	var icon = TextureRect.new()
	icon.texture = _get_display_texture(res)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var name_label = Label.new()
	name_label.text = res.building_name
	info_vbox.add_child(name_label)
	
	var cost_label = Label.new()
	cost_label.text = "가격: " + str(cost) + " 🦴"
	info_vbox.add_child(cost_label)
	
	hbox.add_child(info_vbox)
	
	var buy_button = Button.new()
	buy_button.text = "구입하기"
	buy_button.custom_minimum_size = Vector2(100, 40)
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_button.pressed.connect(func(): _on_buy_pressed(res, cost))
	hbox.add_child(buy_button)
	
	return hbox

func _on_buy_pressed(res: BuildingResource, cost: int) -> void:
	if GameManager.dog_treats >= cost:
		hide()
		GameManager.start_build_mode.emit(res, cost, "shop")
	else:
		print_debug("[ShopUI] Not enough treats! Need: ", cost, " Have: ", GameManager.dog_treats)
		_show_insufficient_funds_feedback()

func _show_insufficient_funds_feedback() -> void:
	## 개꿘이 부족 시 패널을 빨갓게 바꾸고 흔들림 연출을 연주합니다.
	var panel = get_node_or_null("Panel")
	if not panel: return
	
	var original_pos = panel.position
	var original_mod = panel.modulate
	
	var tween = create_tween()
	# 빨강 플래시
	tween.tween_property(panel, "modulate", Color(1.5, 0.5, 0.5, 1.0), 0.1)
	tween.tween_property(panel, "modulate", original_mod, 0.15)
	
	# 좌우 흔들림 (Shake)
	var shake_dist = 6.0
	tween.tween_property(panel, "position", original_pos + Vector2(shake_dist, 0), 0.05)
	tween.tween_property(panel, "position", original_pos + Vector2(-shake_dist, 0), 0.05)
	tween.tween_property(panel, "position", original_pos + Vector2(shake_dist * 0.5, 0), 0.05)
	tween.tween_property(panel, "position", original_pos, 0.05)

func _get_display_texture(res: BuildingResource) -> Texture2D:
	# 사용자 요청: 아이콘과 실제 배치 이미지를 동일하게 하되, 스프라이트 시트면 1프레임만 오려서 표시
	var tex = res.texture
	if not tex:
		return res.icon
		
	if res.hframes * res.vframes > 1:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		var frame_w = tex.get_width() / float(res.hframes)
		var frame_h = tex.get_height() / float(res.vframes)
		atlas.region = Rect2(0, 0, frame_w, frame_h)
		return atlas
		
	return tex
