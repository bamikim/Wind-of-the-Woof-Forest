extends Node2D

## 안개가 서서히 걷히는 연출을 담당하는 스크립트입니다.

func disperse() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self , "modulate:a", 0.0, 1.5)
	tween.tween_property(self , "scale", Vector2(1.2, 1.2), 1.5).set_trans(Tween.TRANS_SINE)
	tween.chain().finished.connect(queue_free)
