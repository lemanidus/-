class_name ClubLogos
extends RefCounted
# Логотипы клубов. Файл ищется по id клуба: res://assets/logos/<id>.png
# (допустимы также webp, svg и jpg). Если файла нет, показывается первая
# буква названия клуба.
#
# Совет: для красивого уменьшения включите у логотипов в панели «Импорт»
# параметр Mipmaps → Generate и нажмите Reimport.

const FOLDER = "res://assets/logos/"
const EXTENSIONS = ["png", "webp", "svg", "jpg"]

static var _cache: Dictionary = {}


static func get_texture(team_id: String) -> Texture2D:
	if _cache.has(team_id):
		return _cache[team_id]
	var tex: Texture2D = null
	for ext in EXTENSIONS:
		var path = "%s%s.%s" % [FOLDER, team_id, ext]
		if ResourceLoader.exists(path):
			tex = load(path)
			break
	_cache[team_id] = tex
	return tex


# Квадратный значок клуба заданного размера для вставки в любой контейнер
static func make_icon(team: Team, size: int) -> Control:
	var tex = get_texture(team.id)
	if tex != null:
		var tr = TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(size, size)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return tr
	
	# Запасной вариант: буква на полупрозрачной плашке
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.12)
	sb.set_corner_radius_all(maxi(size / 5, 4))
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(size, size)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l = Label.new()
	l.text = team.display_name.substr(0, 1).to_upper()
	l.add_theme_font_size_override("font_size", maxi(size / 2, 10))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


# Значок на кнопке (список клубов): если логотипа нет, кнопка остаётся без значка
static func apply_to_button(b: Button, team: Team, size: int) -> void:
	var tex = get_texture(team.id)
	if tex == null:
		return
	b.icon = tex
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", size)
