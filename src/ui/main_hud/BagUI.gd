extends Control

## 가방(인벤토리) 팝업 UI를 제어하는 스크립트입니다.

@onready var close_button: Button = $Panel/CloseButton
@onready var items_grid: GridContainer = $Panel/MarginContainer/ScrollContainer/ItemsGrid

# 빠른 조회를 위한 리소스 캐싱
var resource_library: Dictionary = {}

func _ready() -> void:
	close_button.pressed.connect(hide)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	
	# 리소스 목록 미리 로드
	_preload_resources()
	
	hide() # 기본적으로 숨김

func _preload_resources() -> void:
	var paths = [
		"res://data/buildings/mill.tres",
		"res://data/buildings/pump.tres",
		"res://data/buildings/postbox.tres",
		"res://data/buildings/bamboo_fountain.tres",
		"res://data/buildings/biscuit_rack.tres",
		"res://data/buildings/glass_windchime.tres",
		"res://data/buildings/cloud_observatory.tres",
		"res://data/buildings/bee_planter.tres",
		"res://data/buildings/music_stump.tres",
		"res://data/buildings/vine_streetlight.tres",
		"res://data/buildings/snack_cart.tres",
		"res://data/buildings/cloud_waterwheel.tres",
		"res://data/buildings/balloon_station.tres",
		"res://data/buildings/nap_rock.tres"
	]
	for p in paths:
		var res: BuildingResource = load(p) as BuildingResource
		if res:
			resource_library[res.building_id] = res

func update_bag() -> void:
	# 기존 슬롯 제거
	for child in items_grid.get_children():
		child.queue_free()
	
	# 보유 아이템 기반으로 UI 인스턴스 생성
	for item_id in InventoryManager.inventory:
		var amount = InventoryManager.inventory[item_id]
		if amount > 0 and resource_library.has(item_id):
			var res = resource_library[item_id]
			var slot = _create_item_slot(res, amount)
			items_grid.add_child(slot)

func _create_item_slot(res: BuildingResource, amount: int) -> Control:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(100, 120)
	
	var icon = TextureRect.new()
	icon.texture = _get_display_texture(res)
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon)
	
	var label = Label.new()
	label.text = res.building_name + "\n(소지: " + str(amount) + ")"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(label)
	
	var place_btn = Button.new()
	place_btn.text = "배치하기"
	place_btn.size_flags_vertical = Control.SIZE_SHRINK_END
	place_btn.pressed.connect(func(): _on_place_pressed(res))
	vbox.add_child(place_btn)
	
	return vbox

func _on_place_pressed(res: BuildingResource) -> void:
	# 가방 숨기고 배치 모드 진입
	hide()
	# 배치 모드 요청
	BuildManager.start_build_mode.emit(res, 0, "bag")

func _on_inventory_changed(_item_id: String, _amount: int) -> void:
	# 인벤토리 데이터가 변하면 가방이 열려있든 아니든 UI를 업데이트합니다.
	update_bag()

# 외부에서 가방 열 때 사용하는 헬퍼 함수
func open_bag() -> void:
	update_bag()
	show()

func _get_display_texture(res: BuildingResource) -> Texture2D:
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
