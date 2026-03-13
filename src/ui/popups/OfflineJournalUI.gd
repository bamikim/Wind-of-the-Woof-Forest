extends Control

## 오프라인 시간 동안 완료된 미션 결과와 보상을 보여주는 팝업입니다.

@onready var log_label: Label = $Panel/VBoxContainer/ScrollContainer/LogLabel
@onready var treats_label: Label = $Panel/VBoxContainer/RewardBox/TreatsLabel
@onready var cookies_label: Label = $Panel/VBoxContainer/RewardBox/CookiesLabel
@onready var xp_label: Label = $Panel/VBoxContainer/RewardBox/XpLabel
@onready var confirm_btn: Button = $Panel/VBoxContainer/ConfirmBtn

var total_treats: int = 0
var total_cookies: int = 0
var total_xp: int = 0

const PERSONALITY_LOGS = {
	0: ["오늘도 묵묵히 일을 끝마쳤어요.", "별일 없이 무사히 완료했어요."],
	1: ["너무 신나서 시간 가는 줄 모르고 일했어요!", "꼬리를 붕붕 흔들며 재밌게 해냈어요!"],
	2: ["구석구석 실수 없이 완벽하게 처리했답니다.", "꼼꼼하게 한 번 더 확인하고 마쳤어요!"],
	3: ["중간에 그늘에서 낮잠을 좀 잤지만... 다 했어요.", "조금 졸렸지만 느긋하게 끝냈어요."],
	4: ["이건 어떻게 움직이는 걸까요? 너무 신기했어요!", "일하다가 재미난 냄새를 맡고 구경했어요!"]
}

func _ready() -> void:
	confirm_btn.pressed.connect(_on_confirm_pressed)

func setup(completed_mission_data: Array) -> void:
	var logs = ""
	total_treats = 0
	total_cookies = 0
	total_xp = 0
	
	for data in completed_mission_data:
		var path = data
		var w_name = "강아지"
		var w_per = 0
		var b_amt = 0
		var b_xp = 0
		
		if typeof(data) == TYPE_DICTIONARY:
			path = data.get("m_id", "")
			w_name = data.get("worker_name", "강아지")
			if w_name == "": w_name = "강아지"
			w_per = data.get("worker_personality", 0)
			b_amt = data.get("m_b_amt", 0)
			b_xp = data.get("m_b_xp", 0)
			
		if path == "": continue
		var res = load(path) as MissionResource
		if res:
			var log_msg = PERSONALITY_LOGS.get(w_per, PERSONALITY_LOGS[0]).pick_random()
			logs += "🐾 [%s] %s\n" % [w_name, res.mission_name]
			logs += "   └ \"%s\"\n\n" % log_msg
			
			total_treats += res.reward_amount + b_amt
			total_xp += res.reward_xp + b_xp
			
			if res.extra_reward_id == "cookie" and res.extra_reward_chance > 0:
				if randf() < res.extra_reward_chance:
					total_cookies += 1
					
	if logs == "":
		logs = "- 오프라인 동안 완료된 특별한 미션이 없어요."
		
	log_label.text = logs
	treats_label.text = "🦴 획득한 개껌: %d 개" % total_treats
	cookies_label.text = "🍪 획득한 쿠키: %d 개" % total_cookies
	xp_label.text = "⭐ 획득한 경험치: %d XP" % total_xp

func _on_confirm_pressed() -> void:
	# 보상 일괄 지급
	if total_treats > 0:
		GameManager.dog_treats += total_treats
	if total_cookies > 0:
		GameManager.cookies += total_cookies
	if total_xp > 0:
		GameManager.add_xp(total_xp)
		
	queue_free()
