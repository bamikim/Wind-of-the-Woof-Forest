extends Node

## 건물 배치 및 건설과 관련된 전역 상태와 시그널을 관리하는 싱글톤입니다.

@warning_ignore("unused_signal")
signal start_build_mode(res: Resource, cost: int, source: String)

## 배치 모드가 활성화되어 있는지 여부. 다른 씬에서 읽기 전용으로 참조합니다.
var is_active: bool = false

func emit_start_build_mode(res: Resource, cost: int, source: String) -> void:
	start_build_mode.emit(res, cost, source)

func set_active(value: bool) -> void:
	is_active = value
