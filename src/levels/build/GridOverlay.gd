extends Node2D
class_name GridOverlay

## 빌드 모드일 때 바닥 타일 위에 256x128 크기의 아이소메트릭 그리드를 윤곽선으로 그려줍니다.

@export var tilemap: TileMap
var grid_color: Color = Color(1.0, 1.0, 1.0, 0.15) # 부드러운 흰색 반투명
var is_active: bool = false

func set_active(active: bool) -> void:
	is_active = active
	queue_redraw()

func _draw() -> void:
	if not is_active or not tilemap: return
	
	# 레이어 0(Ground)에 깔려있는 모든 타일 좌표를 가져옵니다.
	var used_cells = tilemap.get_used_cells(0)
	for cell in used_cells:
		var pos = tilemap.map_to_local(cell)
		# 256x128 다이아몬드 윤곽선 포인트 (폭 256, 높이 128이므로 절반씩)
		var points = PackedVector2Array([
			Vector2(0, -64) + pos,
			Vector2(128, 0) + pos,
			Vector2(0, 64) + pos,
			Vector2(-128, 0) + pos,
			Vector2(0, -64) + pos # 닫힌 도형
		])
		draw_polyline(points, grid_color, 2.0, true)
