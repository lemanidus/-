class_name Finance
extends RefCounted
# Финансы клуба игрока. Два слоя:
#  А. Лимит на зарплаты: сумма зарплат клуба не должна превышать лимит
#     (проверка при подписании игроков).
#  Б. Баланс клуба: каждый тур приходят доходы (спонсоры, билеты на домашних
#     матчах) и уходят расходы (зарплаты, прочее); в конце сезона приходят
#     призовые за плей-офф.
#
# Масштаб доходов привязан к лимиту, а лимит к реальным зарплатам клуба:
# клуб, у которого зарплаты близки к лимиту, выходит примерно в ноль,
# а клуб с запасом по лимиту копит деньги на усиление.

const TOURS = 46
const HOME_GAMES = 23

const SPONSOR_SHARE = 0.52      # спонсоры за сезон, доля лимита
const TICKET_SHARE = 0.46       # билеты за сезон, доля лимита (при средней посещаемости)
const OVERHEAD_SHARE = 0.07     # прочие расходы (арена, персонал), доля лимита
const START_BALANCE_SHARE = 0.20
const LIMIT_MARGIN = 1.08       # лимит = максимум из «зарплаты ×1,08» и бюджета из данных

# Призовые по стадии плей-офф (доля лимита):
# 5 чемпион, 4 финалист, 3 полуфинал, 2 четвертьфинал, 1 вылет в 1/8
const PRIZES = {5: 0.12, 4: 0.08, 3: 0.05, 2: 0.03, 1: 0.015}

var payroll_limit: int = 0
var balance: int = 0

# Итоги текущего сезона
var income_sponsors: int = 0
var income_tickets: int = 0
var income_prizes: int = 0
var expense_salaries: int = 0
var expense_other: int = 0

# Последние туры: [{"round", "income", "expenses"}, ...]
var history: Array = []


# ===================== СОЗДАНИЕ =====================

static func get_payroll(team: Team) -> int:
	var total = 0
	for p in team.players:
		total += p.salary
	return total


static func create_for_team(team: Team) -> Finance:
	var f = Finance.new()
	var limit_from_payroll = roundi(get_payroll(team) * LIMIT_MARGIN / 1000000.0) * 1000000
	f.payroll_limit = maxi(limit_from_payroll, team.budget)
	f.balance = roundi(f.payroll_limit * START_BALANCE_SHARE)
	return f


static func money(value: int) -> String:
	return "%.1f млн ₽" % (value / 1000000.0)


# ===================== ЛИМИТ ЗАРПЛАТ (слой А) =====================

func get_free_limit(team: Team) -> int:
	return payroll_limit - get_payroll(team)


# Можно ли подписать игрока с такой зарплатой
func can_sign(team: Team, salary: int) -> bool:
	return balance >= 0 and get_payroll(team) + salary <= payroll_limit


# ===================== БАЛАНС (слой Б) =====================

func get_season_income() -> int:
	return income_sponsors + income_tickets + income_prizes


func get_season_expenses() -> int:
	return expense_salaries + expense_other


func get_season_result() -> int:
	return get_season_income() - get_season_expenses()


# Посещаемость зависит от места в группе (после пяти игр)
func _attendance_factor(team: Team) -> float:
	if team.games_played < 5 or GameState.league == null:
		return 1.0
	var standings = GameState.league.get_group_standings(team.group)
	for i in range(standings.size()):
		if standings[i].id == team.id:
			return 1.15 - 0.06 * i
	return 1.0


# Вызывается после каждого тура регулярки. m = матч клуба в этом туре.
func process_tour(team: Team, m: Match, round_no: int) -> void:
	var sponsors = roundi(payroll_limit * SPONSOR_SHARE / TOURS)
	var tickets = 0
	if m != null and m.home_team_id == team.id:
		tickets = roundi(payroll_limit * TICKET_SHARE / HOME_GAMES * _attendance_factor(team))
	var salaries = roundi(get_payroll(team) / float(TOURS))
	var other = roundi(payroll_limit * OVERHEAD_SHARE / TOURS)
	
	income_sponsors += sponsors
	income_tickets += tickets
	expense_salaries += salaries
	expense_other += other
	balance += sponsors + tickets - salaries - other
	
	history.append({"round": round_no, "income": sponsors + tickets, "expenses": salaries + other})
	if history.size() > 10:
		history.pop_front()


# Призовые в конце сезона. stage: 1 вылет в 1/8 ... 5 чемпион.
func add_prize(stage: int, made_playoff: bool) -> int:
	if not made_playoff:
		return 0
	var prize = roundi(payroll_limit * PRIZES.get(stage, 0.0))
	income_prizes += prize
	balance += prize
	return prize


func start_new_season() -> void:
	income_sponsors = 0
	income_tickets = 0
	income_prizes = 0
	expense_salaries = 0
	expense_other = 0
	history.clear()


# ===================== СОХРАНЕНИЕ =====================

func to_dict() -> Dictionary:
	return {
		"payroll_limit": payroll_limit,
		"balance": balance,
		"income_sponsors": income_sponsors,
		"income_tickets": income_tickets,
		"income_prizes": income_prizes,
		"expense_salaries": expense_salaries,
		"expense_other": expense_other,
		"history": history
	}


static func from_dict(d: Dictionary) -> Finance:
	var f = Finance.new()
	f.payroll_limit = int(d.get("payroll_limit", 0))
	f.balance = int(d.get("balance", 0))
	f.income_sponsors = int(d.get("income_sponsors", 0))
	f.income_tickets = int(d.get("income_tickets", 0))
	f.income_prizes = int(d.get("income_prizes", 0))
	f.expense_salaries = int(d.get("expense_salaries", 0))
	f.expense_other = int(d.get("expense_other", 0))
	for h in d.get("history", []):
		f.history.append({
			"round": int(h.get("round", 0)),
			"income": int(h.get("income", 0)),
			"expenses": int(h.get("expenses", 0))
		})
	return f
