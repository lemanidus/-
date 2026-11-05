class_name Calendar

var matches: Array[Match] = []
var current_round: int = 0
var total_rounds: int = 0
var rounds: Array = []


func generate(teams: Array, double_round: bool = true) -> void:
	matches.clear()
	rounds.clear()
	current_round = 0
	
	var n = teams.size()
	if n < 2:
		return
	
	var has_bye = (n % 2 != 0)
	var team_ids: Array = []
	for t in teams:
		team_ids.append(t.id)
	if has_bye:
		team_ids.append("")
	
	var num_teams = team_ids.size()
	var num_rounds = num_teams - 1
	var half: int = num_teams >> 1
	
	var schedule: Array = []
	var rotation = team_ids.duplicate()
	
	for r in range(num_rounds):
		var round_matches: Array = []
		for i in range(half):
			var home = rotation[i]
			var away = rotation[num_teams - 1 - i]
			if home == "" or away == "":
				continue
			if r % 2 == 1:
				var tmp = home
				home = away
				away = tmp
			var m = Match.new(home, away)
			round_matches.append(m)
		schedule.append(round_matches)
		
		var last = rotation.pop_back()
		rotation.insert(1, last)
	
	if double_round:
		var reverse_schedule: Array = []
		for round_matches in schedule:
			var rev_round: Array = []
			for m in round_matches:
				var rev = Match.new(m.away_team_id, m.home_team_id)
				rev_round.append(rev)
			reverse_schedule.append(rev_round)
		schedule.append_array(reverse_schedule)
	
	rounds = schedule
	total_rounds = schedule.size()
	for round_matches in schedule:
		for m in round_matches:
			matches.append(m)
	
	print("Календарь: ", total_rounds, " туров, ", matches.size(), " матчей")


func get_current_round_matches() -> Array:
	if current_round >= rounds.size():
		return []
	return rounds[current_round]


func next_round() -> bool:
	current_round += 1
	return current_round < rounds.size()


func is_season_over() -> bool:
	return current_round >= rounds.size()


func get_info() -> String:
	return "Тур " + str(current_round + 1) + " из " + str(total_rounds)
