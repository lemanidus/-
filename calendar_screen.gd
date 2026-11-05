extends Control
# Экран «Календарь». Слева 46 туров сезона для клуба игрока: соперник,
# дома или в гостях и результат. Справа выбранный тур целиком:
# кто с кем играет, матч клуба игрока подсвечен.

const C_BG = Color(0.047, 0.141, 0.259)
const C_PANEL = Color(0.114, 0.165, 0.251)
const C_ROW = Color(0.14, 0.2, 0.3)
const C_MINE = Color(0.16, 0.5, 0.66)
const C_ICE = Color(0.4, 0.851, 0.941)
const C_MUTED = Color(0.62, 0.68, 0.76)
const C_SOFT = Color(0.78, 0.84, 0.92)
const C_GREEN = Color(0.45, 1.0, 0.55)
const C_BAD = Color(1.0, 0.5, 0.5)
const C_ORANGE = Color(1.0, 0.75, 0.4)
const C_GOLD = Color(0.91, 0.78, 0.42)

const ROW_H = 44
const ROW_GAP = 4

var my: Team
var selected: int = 0       # индекс выбранного тура (с нуля)
var left_box: VBoxContainer
var left_scroll: ScrollContainer
var right_box: VBoxContainer
var right_title: Label
var left_buttons: Array = []


func _ready() -> void:
	if GameState.current_team == null:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	my = GameState.current_team
	
	var cal = GameState.calendar
	# Открываемся на ближайшем туре, а если сезон сыгран, то на последнем
	selected = mini(cal.current_round, cal.rounds.size() - 1)
	
	_build_ui()
	_rebuild_left()
	_rebuild_right()
	_scroll_to_selected.call_deferred()


# ===================== ПОМОЩНИКИ =====================

func _label(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _make_panel(color: Color, margin: int = 12, radius: int = 14) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _style_button(b: Button, bg: Color, selected_style: bool = false, radius: int = 10) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb = StyleBoxFlat.new()
		var col = bg
		if state == "hover":
			col = bg.lightened(0.08)
		elif state == "pressed":
			col = bg.darkened(0.12)
		sb.bg_color = col
		sb.set_corner_radius_all(radius)
		sb.set_content_margin_all(6)
		if selected_style:
			sb.set_border_width_all(2)
			sb.border_color = C_ICE
		b.add_theme_stylebox_override(state, sb)
	b.focus_mode = Control.FOCUS_NONE


func _suffix(m: Match) -> String:
	if m.shootout:
		return " (Б)"
	if m.overtime:
		return " (ОТ)"
	return ""


# Матч клуба игрока в туре
func _my_match(round_index: int) -> Match:
	for m in GameState.calendar.rounds[round_index]:
		if m.home_team_id == my.id or m.away_team_id == my.id:
			return m
	return null


# ===================== КАРКАС =====================

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = C_BG
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	
	# Верхняя строка
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	root.add_child(top)
	
	var back = Button.new()
	back.text = "← НАЗАД"
	back.custom_minimum_size = Vector2(170, 50)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(_on_back_pressed)
	top.add_child(back)
	
	var title = _label("КАЛЕНДАРЬ · " + my.display_name.to_upper(), 26, C_ICE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(title)
	
	var cal = GameState.calendar
	var info = _label("Сезон %d · сыграно туров: %d из %d" % [GameState.season_number, cal.current_round, cal.total_rounds], 18, C_SOFT)
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(info)
	
	# Тело: слева сезон клуба, справа выбранный тур
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	
	var left = _make_panel(C_PANEL, 10)
	left.custom_minimum_size = Vector2(500, 0)
	body.add_child(left)
	var lv = VBoxContainer.new()
	lv.add_theme_constant_override("separation", 6)
	left.add_child(lv)
	lv.add_child(_label("МОЙ СЕЗОН", 16, C_MUTED))
	
	left_scroll = ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lv.add_child(left_scroll)
	
	left_box = VBoxContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_box.add_theme_constant_override("separation", ROW_GAP)
	left_scroll.add_child(left_box)
	
	var right = _make_panel(C_PANEL, 14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rv = VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	right.add_child(rv)
	
	right_title = _label("", 20, C_GOLD)
	rv.add_child(right_title)
	
	var rscroll = ScrollContainer.new()
	rscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(rscroll)
	
	right_box = VBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.add_theme_constant_override("separation", 4)
	rscroll.add_child(right_box)


# ===================== ЛЕВАЯ ПАНЕЛЬ: СЕЗОН КЛУБА =====================

func _rebuild_left() -> void:
	for c in left_box.get_children():
		left_box.remove_child(c)
		c.queue_free()
	left_buttons.clear()
	
	var cal = GameState.calendar
	var teams = GameState.league.teams_by_id
	
	for i in range(cal.rounds.size()):
		var m = _my_match(i)
		var text = "Тур %d" % (i + 1)
		var color = Color.WHITE
		var result_text = ""
		var result_color = C_MUTED
		var opp_text = "—"
		var opp_team: Team = null
		
		if m != null:
			var is_home = (m.home_team_id == my.id)
			var opp = teams.get(m.away_team_id if is_home else m.home_team_id)
			opp_text = ("дома · " if is_home else "в гостях · ") + (opp.display_name if opp != null else "?")
			opp_team = opp
			
			if m.played:
				var my_goals = m.home_goals if is_home else m.away_goals
				var opp_goals = m.away_goals if is_home else m.home_goals
				var won = my_goals > opp_goals
				var letter = "В"
				if won and m.overtime:
					letter = "ВО"
				elif not won and m.overtime:
					letter = "ПО"
				elif not won:
					letter = "П"
				result_text = "%d:%d %s" % [my_goals, opp_goals, letter]
				if m.shootout:
					result_text += " (Б)"
				result_color = C_GREEN if won else (C_ORANGE if m.overtime else C_BAD)
		
		if i == cal.current_round:
			color = C_ICE
		
		var b = Button.new()
		b.custom_minimum_size = Vector2(0, ROW_H)
		b.focus_mode = Control.FOCUS_NONE
		_style_button(b, C_MINE if i == cal.current_round else C_ROW, i == selected)
		b.pressed.connect(_on_round_pressed.bind(i))
		
		var row = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 10)
		b.add_child(row)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
		
		var l_round = _label(text, 16, color)
		l_round.custom_minimum_size = Vector2(64, 0)
		l_round.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l_round.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l_round)
		
		if opp_team != null:
			row.add_child(ClubLogos.make_icon(opp_team, 28))
		
		var l_opp = _label(opp_text, 16, color if i == cal.current_round else C_SOFT)
		l_opp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l_opp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l_opp.clip_text = true
		l_opp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l_opp)
		
		var l_res = _label(result_text, 16, result_color)
		l_res.custom_minimum_size = Vector2(90, 0)
		l_res.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l_res.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l_res.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l_res)
		
		left_box.add_child(b)
		left_buttons.append(b)


func _scroll_to_selected() -> void:
	left_scroll.scroll_vertical = maxi(0, (selected - 2) * (ROW_H + ROW_GAP))


# ===================== ПРАВАЯ ПАНЕЛЬ: ТУР ЦЕЛИКОМ =====================

func _rebuild_right() -> void:
	for c in right_box.get_children():
		right_box.remove_child(c)
		c.queue_free()
	
	var cal = GameState.calendar
	var status = "сыгран"
	if selected == cal.current_round:
		status = "ближайший"
	elif selected > cal.current_round:
		status = "впереди"
	right_title.text = "ТУР %d из %d · %s" % [selected + 1, cal.total_rounds, status]
	
	var teams = GameState.league.teams_by_id
	for m in cal.rounds[selected]:
		var h = teams.get(m.home_team_id)
		var a = teams.get(m.away_team_id)
		if h == null or a == null:
			continue
		
		var mine = (m.home_team_id == my.id or m.away_team_id == my.id)
		var panel = _make_panel(C_MINE if mine else C_ROW, 0, 8)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		
		var hl = _label(h.display_name, 17, Color.WHITE)
		hl.custom_minimum_size = Vector2(0, 36)
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hl.clip_text = true
		row.add_child(hl)
		row.add_child(ClubLogos.make_icon(h, 28))
		
		var score_text = "—"
		var score_color = C_MUTED
		if m.played:
			score_text = "%d : %d%s" % [m.home_goals, m.away_goals, _suffix(m)]
			score_color = Color.WHITE
		var sl = _label(score_text, 17, score_color)
		sl.custom_minimum_size = Vector2(110, 36)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(sl)
		row.add_child(ClubLogos.make_icon(a, 28))
		
		var al = _label(a.display_name, 17, Color.WHITE)
		al.custom_minimum_size = Vector2(0, 36)
		al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		al.clip_text = true
		row.add_child(al)
		
		right_box.add_child(panel)


# ===================== ДЕЙСТВИЯ =====================

func _on_round_pressed(index: int) -> void:
	selected = index
	# Перерисовываем только рамку выбранной строки и правую панель
	for i in range(left_buttons.size()):
		var cal = GameState.calendar
		_style_button(left_buttons[i], C_MINE if i == cal.current_round else C_ROW, i == selected)
	_rebuild_right()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub.tscn")
