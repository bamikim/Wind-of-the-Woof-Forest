extends Node

## 배경음(BGM) 및 효과음(SFX)을 총괄 관리하는 싱글톤입니다.

var bgm_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8

func _ready() -> void:
	# BGM 플레이어 초기화
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# SFX 풀 초기화
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)
	
	print_debug("[SoundManager] Sound systems ready.")

func play_bgm(stream: AudioStream, volume: float = 0.0) -> void:
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.volume_db = volume
	bgm_player.play()

func play_sfx(stream: AudioStream, volume: float = 0.0) -> void:
	for p in sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume
			p.play()
			return
	
	# 풀이 꽉 찼을 경우 첫 번째 플레이어 재사용
	sfx_pool[0].stream = stream
	sfx_pool[0].play()
