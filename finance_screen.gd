extends Control
# Экран «Финансы». Слева баланс клуба и доходы/расходы сезона,
# справа лимит зарплат и результат последних туров.

const C_BG = Color(0.047, 0.141, 0.259)
const C_PANEL = Color(0.114, 0.165, 0.251)
const C_CARD = Color(0.165, 0.286, 0.447)
const C_ICE = Color(0.4, 0.851, 0.941)
const C_MUTED = Color(0.62, 0.68, 0.76)
const C_SOFT = Color(0.78, 0.84, 0.92)
const C_GREEN = Color(0.45, 1.0, 0.55)
const C_BAD = Color(1.0, 0.5, 0.5)
const C_ORANGE = Color(1.0, 0.75, 0.4)

var my: Team
var fin: Finance


func _ready() -> void:
	if GameState.current_team == null:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	my = GameState.current_team
	if GameState.finance == null:
		GameState.finance = Finance.create_for_team(my)
	fin = GameState.finance
	_build_ui()


# ===================== ПОМОЩНИКИ =====================

func _label(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _make_panel(color: Color, margin: int = 14) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(margin)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _signed_money(value: int) -> String:
	return ("+" if value > 0 else "") + Finance.money(value)


func _line(title: String, value: String, color: Color = Color.WHITE) -> HBoxContainer:
	var row = HBoxContainer.new()
	var t = _label(title, 16, C_SOFT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	var v = _label(value, 16, color)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	return row


# ===================== ЭКРАН =====================

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
	root.add_theme_constant_override("separation", 12)
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
	
	var title = _label("ФИНАНСЫ · " + my.display_name.to_upper(), 26, C_ICE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(title)
	
	var cal = GameState.calendar
	var info = _label("Сезон %d · Тур %d/%d" % [GameState.season_number, cal.current_round, cal.total_rounds], 18, C_SOFT)
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(info)
	
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	
	_build_left(body)
	_build_right(body)


func _build_left(body: HBoxContainer) -> void:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	body.add_child(col)
	
	# Баланс клуба
	var bal_panel = _make_panel(C_CARD, 16)
	col.add_child(bal_panel)
	var bv = VBoxContainer.new()
	bv.add_theme_constant_override("separation", 2)
	bal_panel.add_child(bv)
	bv.add_child(_label("БАЛАНС КЛУБА", 16, C_MUTED))
	bv.add_child(_label(Finance.money(fin.balance), 44, C_GREEN if fin.balance >= 0 else C_BAD))
	var result = fin.get_season_result()
	var result_color = C_GREEN if result > 0 else (C_BAD if result < 0 else C_SOFT)
	bv.add_child(_label("Итог сезона на сейчас: " + _signed_money(result), 18, result_color))
	
	# Доходы и расходы
	var row = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	
	var inc = _make_panel(C_PANEL, 16)
	inc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(inc)
	var iv = VBoxContainer.new()
	iv.add_theme_constant_override("separation", 6)
	inc.add_child(iv)
	iv.add_child(_label("ДОХОД ЗА СЕЗОН", 16, C_MUTED))
	iv.add_child(_label(Finance.money(fin.get_season_income()), 28, C_GREEN))
	iv.add_child(_line("Спонсоры", Finance.money(fin.income_sponsors)))
	iv.add_child(_line("Билеты", Finance.money(fin.income_tickets)))
	iv.add_child(_line("Призовые", Finance.money(fin.income_prizes)))
	
	var exp_panel = _make_panel(C_PANEL, 16)
	exp_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(exp_panel)
	var ev = VBoxContainer.new()
	ev.add_theme_constant_override("separation", 6)
	exp_panel.add_child(ev)
	ev.add_child(_label("ЗАТРАТЫ ЗА СЕЗОН", 16, C_MUTED))
	ev.add_child(_label(Finance.money(fin.get_season_expenses()), 28, C_BAD))
	ev.add_child(_line("Зарплаты", Finance.money(fin.expense_salaries)))
	ev.add_child(_line("Прочее", Finance.money(fin.expense_other)))


func _build_right(body: HBoxContainer) -> void:
	var col = VBoxContainer.new()
	col.custom_minimum_size = Vector2(430, 0)
	col.add_theme_constant_override("separation", 12)
	body.add_child(col)
	
	# Лимит зарплат
	var lim = _make_panel(C_PANEL, 16)
	col.add_child(lim)
	var lv = VBoxContainer.new()
	lv.add_theme_constant_override("separation", 6)
	lim.add_child(lv)
	lv.add_child(_label("ЛИМИТ ЗАРПЛАТ", 16, C_MUTED))
	
	var payroll = Finance.get_payroll(my)
	var free_limit = fin.get_free_limit(my)
	
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = clampf(100.0 * payroll / maxi(fin.payroll_limit, 1), 0.0, 100.0)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 20)
	lv.add_child(bar)
	
	lv.add_child(_line("Зарплаты клуба", Finance.money(payroll)))
	lv.add_child(_line("Лимит", Finance.money(fin.payroll_limit)))
	lv.add_child(_line("Свободно", Finance.money(free_limit), C_GREEN if free_limit >= 0 else C_BAD))
	
	var note = _label("Подписать игрока можно, только если зарплаты клуба после этого не превысят лимит. Зарплаты списываются с баланса каждый тур.", 14, C_MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_child(note)
	
	# Последние туры
	var hist = _make_panel(C_PANEL, 16)
	hist.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(hist)
	var hv = VBoxContainer.new()
	hv.add_theme_constant_override("separation", 3)
	hist.add_child(hv)
	hv.add_child(_label("ПОСЛЕДНИЕ ТУРЫ (млн ₽)", 16, C_MUTED))
	
	if fin.history.is_empty():
		hv.add_child(_label("Пока нет сыгранных туров.", 15, C_MUTED))
	else:
		var scroll = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		hv.add_child(scroll)
		var list = VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 3)
		scroll.add_child(list)
		
		var rows = fin.history.duplicate()
		rows.reverse()
		for h in rows:
			var net = h["income"] - h["expenses"]
			var text = "Тур %d:  +%.1f  −%.1f  =  %+.1f" % [h["round"], h["income"] / 1000000.0, h["expenses"] / 1000000.0, net / 1000000.0]
			list.add_child(_label(text, 15, C_GREEN if net >= 0 else C_ORANGE))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub.tscn")
