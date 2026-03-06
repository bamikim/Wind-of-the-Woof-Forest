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
	icon.texture = res.icon if res.icon else res.texture
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
		print_debug("Not enough treats!")
		# 돈 부족 피드백 연출 (옵션)
