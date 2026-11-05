extends Node

var manager_name: String = "Менеджер"
var current_team_id: String = ""
var current_team: Team = null
var season_number: int = 1

var season_goal: String = ""
var season_goal_type: String = ""
var last_season_result: String = ""
var last_season_goal_met: int = 0
var last_season_move: String = ""

var league: League = null
var calendar: Calendar = null
var playoff: Playoff = null
var in_playoff: bool = false

# Состав клуба игрока на игру (схема, звенья, вратари)
var lineup: Lineup = null

# Тактика клуба игрока (ключ из MatchEngine.TACTICS)
var tactic: String = "standard"

# Финансы клуба игрока (лимит зарплат и баланс)
var finance: Finance = null

# Трансферы: пул свободных агентов, счётчик id для новых игроков,
# куда вернуться с экрана трансферов и уведомление для хаба
var free_agents: Array = []
var fa_counter: int = 0
var transfers_back: String = "res://scenes/hub.tscn"
var pending_notice: String = ""

# Живой матч клуба игрока (идёт, пока открыт экран матча и экраны смены состава)
var live_session: MatchSession = null

# Последний матч клуба игрока (для экрана итогов матча)
var last_match: Match = null


func get_goal_text_for_group(group: String) -> String:
	match group:
		"A": return "Выйти в финал Кубка ЛВХ"
		"B": return "Попасть в плей-офф"
		"C": return "Не вылететь в группу D"
		"D": return "Подняться в группу C"
		_: return "Выполнить задачу руководства"


func set_goal_for_team(team: Team):
	current_team = team
	current_team_id = team.id
	season_goal = get_goal_text_for_group(team.group)
	season_goal_type = _get_goal_type(team.group)


func _get_goal_type(group: String) -> String:
	match group:
		"A": return "final"
		"B": return "playoff"
		"C": return "stay"
		"D": return "promote"
		_: return "stay"


func evaluate_season(team_position: int, made_playoff: bool, playoff_stage: int, moved_up: bool, moved_down: bool) -> Dictionary:
	var result = {"met": 0, "message": ""}
	
	match season_goal_type:
		"final":
			if playoff_stage >= 4:
				result["met"] = 2
				result["message"] = "Вы вышли в финал! Цель выполнена."
			elif playoff_stage >= 3:
				result["met"] = 1
				result["message"] = "Вы дошли до 1/2. Цель частично выполнена."
			else:
				result["met"] = 0
				result["message"] = "Вы не дошли до финала. Цель не выполнена."
		
		"playoff":
			if made_playoff:
				result["met"] = 2
				result["message"] = "Вы попали в плей-офф. Цель выполнена."
			elif team_position <= 5:
				result["met"] = 1
				result["message"] = "Вы были близки к плей-офф. Цель частично выполнена."
			else:
				result["met"] = 0
				result["message"] = "Вы не попали в плей-офф. Цель не выполнена."
		
		"stay":
			if not moved_down:
				result["met"] = 2
				result["message"] = "Вы остались в группе. Цель выполнена."
			else:
				result["met"] = 0
				result["message"] = "Вы вылетели в группу D. Цель не выполнена."
		
		"promote":
			if moved_up:
				result["met"] = 2
				result["message"] = "Вы поднялись в группу C! Цель выполнена."
			elif team_position <= 3:
				result["met"] = 1
				result["message"] = "Вы были близки к повышению. Цель частично выполнена."
			else:
				result["met"] = 0
				result["message"] = "Вы не поднялись. Цель не выполнена."
	
	last_season_goal_met = result["met"]
	last_season_result = result["message"]
	return result


func reset():
	manager_name = "Менеджер"
	current_team_id = ""
	current_team = null
	season_number = 1
	season_goal = ""
	season_goal_type = ""
	last_season_result = ""
	last_season_goal_met = 0
	last_season_move = ""
	league = null
	calendar = null
	playoff = null
	in_playoff = false
	lineup = null
	tactic = "standard"
	finance = null
	free_agents = []
	fa_counter = 0
	transfers_back = "res://scenes/hub.tscn"
	pending_notice = ""
	live_session = null
	last_match = null


# Открыт ли экран смены тактики или звеньев прямо во время матча
func is_live_edit() -> bool:
	return live_session != null and live_session.editing
