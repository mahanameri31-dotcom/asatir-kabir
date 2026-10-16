extends Node3D

const SAVE_PATH := "user://asatir_save.json"
const HEROES := {
	"رستم": {"price": 0, "kind": "warrior"},
	"آرش کمانگیر": {"price": 600, "kind": "archer"},
	"سهراب": {"price": 900, "kind": "warrior"},
	"فردوسی": {"price": 2500, "kind": "special"},
	"حافظ شیرازی": {"price": 3500, "kind": "special"}
}
var profile_name := "پهلوان"
var rename_used := false
var coins := 1200
var diamonds := 300
var cups := 0
var xp := 0
var level := 1
var troops_level := 1
var archers_level := 1
var hero_level := 1
var owned_heroes: Array[String] = ["رستم"]
var daily_spin_date := ""
var weekly_spin_key := ""
var message := "به سرزمین اساطیر خوش آمدی!"
var arena: Node3D
var ui: Control
var status_label: Label
var stats_label: Label
var content: VBoxContainer
var current_tab := "قلمرو"

func _ready() -> void:
	_build_world()
	_load_game()
	_build_ui()
	_refresh_ui()

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.35
	add_child(sun)
	arena = Node3D.new()
	arena.name = "Arena"
	add_child(arena)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(34, 34)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("263c32")
	mat.roughness = 0.92
	floor_mesh.material_override = mat
	arena.add_child(floor_mesh)
	for x in range(-15, 16, 3):
		for z in range(-15, 16, 3):
			var tile := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(2.92, 0.035, 2.92)
			tile.mesh = box
			tile.position = Vector3(x, 0.025, z)
			var tile_mat := StandardMaterial3D.new()
			tile_mat.albedo_color = Color("304b3a") if ((x + z) / 3) % 2 == 0 else Color("2b4436")
			tile.material_override = tile_mat
			arena.add_child(tile)
	_add_placeholder_unit(Vector3(-3, 0.6, 1), Color("c99b44"), "قهرمان")
	_add_placeholder_unit(Vector3(3, 0.6, -1), Color("a94a43"), "دشمن")
	var camera := Camera3D.new()
	camera.position = Vector3(0, 17, 16)
	camera.rotation_degrees = Vector3(-47, 0, 0)
	camera.current = true
	camera.fov = 52
	add_child(camera)

func _add_placeholder_unit(pos: Vector3, tint: Color, label_text: String) -> void:
	var unit := Node3D.new()
	unit.position = pos
	arena.add_child(unit)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.35
	body.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.25
	body.material_override = material
	unit.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.27
	sphere.height = 0.54
	head.mesh = sphere
	head.position.y = 0.83
	head.material_override = material
	unit.add_child(head)

func _build_ui() -> void:
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 76
	ui.add_child(top)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	var title := Label.new()
	title.text = "اساطیر"
	title.add_theme_font_size_override("font_size", 30)
	top_row.add_child(title)
	stats_label = Label.new()
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(stats_label)
	var nav := HBoxContainer.new()
	nav.set_anchors_preset(Control.PRESET_TOP_WIDE)
	nav.offset_top = 78
	nav.offset_bottom = 126
	ui.add_child(nav)
	for tab in ["قلمرو", "نبرد", "قهرمانان", "ارتقا", "گردونه", "رتبه‌بندی", "پروفایل"]:
		var b := Button.new()
		b.text = tab
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_show_tab.bind(tab))
		nav.add_child(b)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -300
	panel.offset_bottom = -12
	panel.offset_left = 12
	panel.offset_right = -12
	panel.custom_minimum_size.y = 280
	ui.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	status_label = Label.new()
	status_label.text = message
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(status_label)
	status_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	status_label.offset_top = -330
	status_label.offset_bottom = -305
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _refresh_ui() -> void:
	stats_label.text = "💎 %d    🪙 %d    🏆 %d    سطح %d" % [diamonds, coins, cups, level]
	status_label.text = message
	_show_tab(current_tab, false)

func _show_tab(tab: String, set_message: bool = true) -> void:
	current_tab = tab
	if set_message:
		message = "بخش %s" % tab
	for child in content.get_children():
		child.queue_free()
	match tab:
		"قلمرو":
			_add_heading("قلمرو ایرانی تو")
			_add_text("قلمرو سه‌بعدی نمونه؛ این نسخه هنوز مدل‌های نهایی و حمله آنلاین ندارد.")
			_add_button("آغاز نبرد برای جام و پاداش", _start_battle)
			_add_button("ارتقای سربازان", _show_tab.bind("ارتقا"))
		"نبرد":
			_add_heading("میدان نبرد")
			_add_text("نیروها را مستقر کن و فرمان ویژه قهرمان را در نسخه‌های بعدی به کار ببر.")
			_add_button("شبیه‌سازی پیروزی", _finish_battle.bind(true))
			_add_button("شبیه‌سازی شکست", _finish_battle.bind(false))
		"قهرمانان":
			_add_heading("قهرمانان اسطوره‌ای")
			for hero in HEROES.keys():
				var price: int = HEROES[hero]["price"]
				_add_button(("%s — آزاد شده" % hero) if owned_heroes.has(hero) else ("خرید %s — %d الماس" % [hero, price]), _buy_hero.bind(hero))
		"ارتقا":
			_add_heading("ارتقای نیروها")
			_add_text("سطح سرباز: %d | کماندار: %d | قهرمان: %d" % [troops_level, archers_level, hero_level])
			_add_button("ارتقای سربازان — ۲۰۰ سکه", _upgrade.bind("troops"))
			_add_button("ارتقای کمانداران — ۲۵۰ سکه", _upgrade.bind("archers"))
			_add_button("ارتقای قهرمان — ۳۰۰ سکه", _upgrade.bind("hero"))
		"گردونه":
			_add_heading("گردونه‌های جایزه")
			_add_button("گردونه روزانه", _spin.bind(false))
			_add_button("گردونه هفتگی — شانس ۳٪ برای ۱۰۰ الماس", _spin.bind(true))
		"رتبه‌بندی":
			_add_heading("جدول رتبه‌بندی نمونه")
			_add_text("۱. رستم‌یار — ۲۴۵۰ جام\n۲. آرش‌کمان — ۱۹۸۰ جام\n۳. %s — %d جام\nاین جدول محلی و آزمایشی است، نه جهانی/آنلاین." % [profile_name, cups])
		"پروفایل":
			_add_heading("پروفایل بازیکن")
			_add_text("نام: %s\nتغییر نام: %s" % [profile_name, "۱۰۰ الماس" if rename_used else "بار اول رایگان"])
			var edit := LineEdit.new()
			edit.name = "NewName"
			edit.placeholder_text = "نام جدید را وارد کن"
			content.add_child(edit)
			_add_button("ثبت نام جدید", _change_name.bind(edit))
			_add_button("ذخیره پیشرفت", _save_game)
		_:
			_add_text("به‌زودی")
	if set_message:
		status_label.text = message

func _add_heading(value: String) -> void:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", 22)
	content.add_child(l)

func _add_text(value: String) -> void:
	var l := Label.new()
	l.text = value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(l)

func _add_button(value: String, action: Callable) -> void:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size.y = 38
	b.pressed.connect(action)
	content.add_child(b)

func _start_battle() -> void:
	message = "نبرد آغاز شد! این مرحله آزمایشی است؛ نتیجه را انتخاب کن."
	_show_tab("نبرد", false)
	_refresh_ui()

func _finish_battle(won: bool) -> void:
	if won:
		diamonds += 5
		coins += 400
		cups += 25
		xp += 50
		message = "پیروزی! ۵ الماس و ۴۰۰ سکه گرفتی."
		if randf() < 0.05:
			diamonds += 50
			message += " شانس ویژه فعال شد: ۵۰ الماس اضافه!"
	else:
		coins += 100
		message = "شکست خوردی؛ ۱۰۰ سکه گرفتی و الماسی دریافت نکردی."
	if xp >= level * 100:
		xp -= level * 100
		level += 1
	_save_game()
	_refresh_ui()

func _buy_hero(hero: String) -> void:
	if owned_heroes.has(hero):
		message = "%s از قبل در اختیار توست." % hero
	elif diamonds < int(HEROES[hero]["price"]):
		message = "الماس کافی نداری."
	else:
		diamonds -= int(HEROES[hero]["price"])
		owned_heroes.append(hero)
		message = "%s به مجموعه قهرمانانت اضافه شد!" % hero
	_save_game()
	_refresh_ui()

func _upgrade(which: String) -> void:
	var price := 200 if which == "troops" else (250 if which == "archers" else 300)
	if coins < price:
		message = "سکه کافی نداری."
	else:
		coins -= price
		if which == "troops": troops_level += 1
		elif which == "archers": archers_level += 1
		else: hero_level += 1
		message = "ارتقا انجام شد!"
	_save_game()
	_refresh_ui()

func _spin(weekly: bool) -> void:
	var now := Time.get_datetime_dict_from_system()
	var today := "%04d-%02d-%02d" % [now.year, now.month, now.day]
	var week_key := "%04d-%02d-W%02d" % [now.year, now.month, int((now.day - 1) / 7) + 1]
	if weekly and weekly_spin_key == week_key:
		message = "گردونه هفتگی را قبلاً چرخانده‌ای."
	elif not weekly and daily_spin_date == today:
		message = "گردونه روزانه را قبلاً چرخانده‌ای."
	else:
		if weekly:
			weekly_spin_key = week_key
			if randf() < 0.03:
				diamonds += 100
				message = "با گردونه هفتگی ۱۰۰ الماس بردی!"
			else:
				var reward := randi_range(100, 400)
				coins += reward
				message = "گردونه هفتگی: %d سکه" % reward
		else:
			daily_spin_date = today
			var roll := randf()
			if roll < 0.08:
				diamonds += 10
				message = "گردونه روزانه: ۱۰ الماس!"
			else:
				var reward := randi_range(100, 300)
				coins += reward
				message = "گردونه روزانه: %d سکه" % reward
	_save_game()
	_refresh_ui()

func _change_name(edit: LineEdit) -> void:
	var new_name := edit.text.strip_edges()
	if new_name.is_empty():
		message = "اول یک نام وارد کن."
	elif rename_used and diamonds < 100:
		message = "برای تغییر نام بعدی ۱۰۰ الماس لازم داری."
	else:
		if rename_used: diamonds -= 100
		profile_name = new_name
		rename_used = true
		message = "نام پروفایل تغییر کرد."
	_save_game()
	_refresh_ui()

func _save_game() -> void:
	var data := {"profile_name": profile_name, "rename_used": rename_used, "coins": coins, "diamonds": diamonds, "cups": cups, "xp": xp, "level": level, "troops_level": troops_level, "archers_level": archers_level, "hero_level": hero_level, "owned_heroes": owned_heroes, "daily_spin_date": daily_spin_date, "weekly_spin_key": weekly_spin_key}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		message += " (ذخیره شد)"

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY: return
	profile_name = str(parsed.get("profile_name", profile_name))
	rename_used = bool(parsed.get("rename_used", rename_used))
	coins = int(parsed.get("coins", coins))
	diamonds = int(parsed.get("diamonds", diamonds))
	cups = int(parsed.get("cups", cups))
	xp = int(parsed.get("xp", xp))
	level = int(parsed.get("level", level))
	troops_level = int(parsed.get("troops_level", troops_level))
	archers_level = int(parsed.get("archers_level", archers_level))
	hero_level = int(parsed.get("hero_level", hero_level))
	owned_heroes.clear()
	for h in parsed.get("owned_heroes", ["رستم"]): owned_heroes.append(str(h))
	daily_spin_date = str(parsed.get("daily_spin_date", ""))
	weekly_spin_key = str(parsed.get("weekly_spin_key", ""))
