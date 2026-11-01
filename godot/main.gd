extends Node3D

# A self-contained Godot 4 vertical slice. All geometry is generated in-engine.
const TYPES := ["water", "earth", "light", "storm"]
const GLYPHS := ["💧", "🌿", "✦", "⚡"]
var hero: CharacterBody3D
var guardian: CharacterBody3D
var camera: Camera3D
var hero_visual: Node3D
var guardian_visual: Node3D
var ui: CanvasLayer
var headline: Label
var information: Label
var life_bar: ProgressBar
var enemy_bar: ProgressBar
var mana_label: Label
var rune_panel: PanelContainer
var rune_grid: GridContainer
var rune_status: Label
var rune_tiles: Array[int] = []
var selected := -1
var rune_moves := 7
var water_energy := 0
var mana := 0
var hp := 100.0
var guardian_hp := 140.0
var cooldown := 0.0
var strike_flash := 0.0
var dodge_time := 0.0
var attack_time := 0.0
var enemy_attack := 1.2
var game_over := false
var puzzle_open := false
var heading_time := 0.0
var touch_dir := Vector2.ZERO
var random := RandomNumberGenerator.new()
var swan_location := Vector3(13, 0, -11)
var light_beacon: OmniLight3D

func _ready() -> void:
	random.seed = 1099
	_build_world()
	_build_characters()
	_build_ui()
	_message("Find the guardian. Weave water runes to charge magic.")
	
func _material(color: Color, metallic := 0.0, emission := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.85
	if emission:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2.0
	return m

func _block(where: Vector3, size: Vector3, color: Color, parent: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	mesh.position = where
	parent.add_child(mesh)
	return mesh

func _sphere(where: Vector3, scale_size: Vector3, color: Color, parent: Node3D = self, glows := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 1.0
	shape.height = 2.0
	mesh.mesh = shape
	mesh.scale = scale_size
	mesh.position = where
	mesh.material_override = _material(color, 0.0, glows)
	parent.add_child(mesh)
	return mesh

func _cylinder(where: Vector3, radius: float, height: float, color: Color, parent: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	mesh.mesh = shape
	mesh.position = where
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	return mesh

func _build_world() -> void:
	_block(Vector3(0, -1.2, 0), Vector3(36, 2, 36), Color("#648d70"))
	_block(Vector3(0, -2.2, 0), Vector3(39, 1, 39), Color("#416d7b"))
	_block(Vector3(0, -2.8, 0), Vector3(120, 0.2, 120), Color("#1d6575"))
	for i in range(24):
		var x := random.randf_range(-16, 16)
		var z := random.randf_range(-16, 16)
		if abs(x) < 5.0 and abs(z) < 7.0:
			continue
		_cylinder(Vector3(x, 1.1, z), 0.26, 2.8, Color("#705641"))
		_sphere(Vector3(x, 3.0, z), Vector3(1.4, 2.3, 1.4), Color("#326b57"))
		_sphere(Vector3(x + 0.65, 3.6, z), Vector3(1.05, 1.25, 1.05), Color("#4c9472"))
	for i in range(11):
		var angle := TAU * float(i) / 11.0
		var pos := Vector3(cos(angle) * 12.5, 1.35, sin(angle) * 12.5)
		_block(pos, Vector3(1.3, 2.8, 0.7), Color("#8c9990")).rotation.y = angle
	for i in range(36):
		var p := Vector3(random.randf_range(-17, 17), 0.0, random.randf_range(-17, 17))
		_sphere(p, Vector3(0.32, 0.11, 0.32), Color("#d8bf76"))
	for j in range(4):
		var pos := swan_location + Vector3(j * 0.8 - 1.2, 0, 0)
		_sphere(pos + Vector3(0, 0.38, 0), Vector3(0.53, 0.37, 0.75), Color("#f6f5e7"))
		_cylinder(pos + Vector3(0.28, 0.83, 0), 0.12, 0.7, Color("#f6f5e7"))
		_sphere(pos + Vector3(0.28, 1.23, 0), Vector3(0.23, 0.23, 0.23), Color("#f6f5e7"))
	_sphere(swan_location + Vector3(0, 2.5, 0), Vector3(0.4, 0.4, 0.4), Color("#f3cb7a"), self, true)
	light_beacon = OmniLight3D.new()
	light_beacon.position = swan_location + Vector3(0, 3.8, 0)
	light_beacon.light_color = Color("#ffd688")
	light_beacon.light_energy = 1.9
	light_beacon.omni_range = 11
	add_child(light_beacon)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-53, -26, 0)
	sun.light_color = Color("#ffe0ac")
	sun.light_energy = 1.45
	add_child(sun)
	var ambient := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#83b2bb")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b8d7ca")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambient.environment = env
	add_child(ambient)

func _new_body(pos: Vector3, collision_radius: float) -> CharacterBody3D:
	var b := CharacterBody3D.new()
	b.position = pos
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = collision_radius
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.86
	b.add_child(shape)
	add_child(b)
	return b

func _build_characters() -> void:
	hero = _new_body(Vector3(-11, 0, 8), 0.45)
	hero_visual = Node3D.new()
	hero.add_child(hero_visual)
	_cylinder(Vector3(0, 1.04, 0), 0.4, 1.15, Color("#8eaca8"), hero_visual)
	_sphere(Vector3(0, 1.91, 0), Vector3(0.31, 0.36, 0.31), Color("#dcb48a"), hero_visual)
	_block(Vector3(-0.54, 1.07, 0), Vector3(0.33, 0.82, 0.4), Color("#607a8d"), hero_visual)
	_block(Vector3(0.53, 1.08, 0), Vector3(0.3, 0.84, 0.4), Color("#607a8d"), hero_visual)
	_block(Vector3(0.64, 1.43, -0.18), Vector3(0.09, 1.5, 0.14), Color("#d9eaf2"), hero_visual)
	_sphere(Vector3(0, 2.22, 0), Vector3(0.41, 0.19, 0.38), Color("#6b5143"), hero_visual)
	guardian = _new_body(Vector3(8, 0, -6), 0.65)
	guardian_visual = Node3D.new()
	guardian.add_child(guardian_visual)
	_sphere(Vector3(0, 1.05, 0), Vector3(0.95, 1.25, 0.78), Color("#323c53"), guardian_visual)
	_sphere(Vector3(0, 2.07, 0), Vector3(0.64, 0.56, 0.61), Color("#3e4d58"), guardian_visual)
	_sphere(Vector3(-0.23, 2.2, -0.53), Vector3(0.12, 0.12, 0.1), Color("#ff6d58"), guardian_visual, true)
	_sphere(Vector3(0.23, 2.2, -0.53), Vector3(0.12, 0.12, 0.1), Color("#ff6d58"), guardian_visual, true)
	_cylinder(Vector3(-1.0, 0.85, 0), 0.24, 1.5, Color("#424c63"), guardian_visual)
	_cylinder(Vector3(1.0, 0.85, 0), 0.24, 1.5, Color("#424c63"), guardian_visual)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 53
	add_child(camera)
	camera.position = hero.position + Vector3(12, 17, 19)
	camera.look_at(hero.position + Vector3(0, 1, 0))

func _button(parent: Node, txt: String, cb: Callable, min_width := 84) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(min_width, 62)
	parent.add_child(b)
	b.pressed.connect(cb)
	return b

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_right = -18
	top.offset_top = 10
	ui.add_child(top)
	headline = Label.new()
	headline.text = "LEGENDS OF ÉIRE — GUARDIAN OF THE LAKE"
	headline.add_theme_font_size_override("font_size", 23)
	top.add_child(headline)
	var gauges := HBoxContainer.new()
	top.add_child(gauges)
	life_bar = ProgressBar.new()
	life_bar.custom_minimum_size = Vector2(210, 20)
	life_bar.max_value = 100
	life_bar.value = 100
	gauges.add_child(life_bar)
	enemy_bar = ProgressBar.new()
	enemy_bar.custom_minimum_size = Vector2(210, 20)
	enemy_bar.max_value = 140
	enemy_bar.value = 140
	gauges.add_child(enemy_bar)
	mana_label = Label.new()
	mana_label.text = "  WATER MAGIC 0/3"
	gauges.add_child(mana_label)
	information = Label.new()
	information.add_theme_font_size_override("font_size", 18)
	top.add_child(information)
	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 18
	bottom.offset_right = -18
	bottom.offset_top = -89
	ui.add_child(bottom)
	var left := HBoxContainer.new()
	bottom.add_child(left)
	_hold_button(left, "◀", Vector2(-1, 0))
	_hold_button(left, "▲", Vector2(0, -1))
	_hold_button(left, "▼", Vector2(0, 1))
	_hold_button(left, "▶", Vector2(1, 0))
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(space)
	_button(bottom, "SWORD", _attack)
	_button(bottom, "DODGE", _dodge)
	_button(bottom, "RUNES", _rune_action)
	var popup := PanelContainer.new()
	rune_panel = popup
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.custom_minimum_size = Vector2(370, 450)
	popup.position = Vector2(455, 120)
	popup.visible = false
	ui.add_child(popup)
	var contents := VBoxContainer.new()
	popup.add_child(contents)
	var title := Label.new()
	title.text = "RUNEWEAVING — MATCH THREE"
	contents.add_child(title)
	rune_status = Label.new()
	contents.add_child(rune_status)
	rune_grid = GridContainer.new()
	rune_grid.columns = 4
	contents.add_child(rune_grid)
	var choices := HBoxContainer.new()
	contents.add_child(choices)
	_button(choices, "RESET", _new_rune_board)
	_button(choices, "CLOSE", _close_runes)
	_update_ui()

func _hold_button(parent: Node, label_text: String, direction: Vector2) -> void:
	var b := _button(parent, label_text, func(): pass, 66)
	b.button_down.connect(func(): touch_dir += direction)
	b.button_up.connect(func(): touch_dir -= direction)

func _message(message: String) -> void:
	if information:
		information.text = message
		heading_time = 3.0

func _update_ui() -> void:
	if life_bar:
		life_bar.value = hp
		enemy_bar.value = guardian_hp
		mana_label.text = "  WATER MAGIC %d/3" % mana

func _process(delta: float) -> void:
	if not hero:
		return
	if puzzle_open or game_over:
		return
	cooldown = maxf(0.0, cooldown - delta)
	dodge_time = maxf(0.0, dodge_time - delta)
	attack_time = maxf(0.0, attack_time - delta)
	strike_flash = maxf(0.0, strike_flash - delta)
	heading_time = maxf(0.0, heading_time - delta)
	var input := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_forward", "move_back")) + touch_dir
	if input.length_squared() > 1.0:
		input = input.normalized()
	var move := Vector3(input.x, 0, input.y)
	hero.position += move * delta * (12.0 if dodge_time > 0 else 6.2)
	hero.position.x = clampf(hero.position.x, -17.0, 17.0)
	hero.position.z = clampf(hero.position.z, -17.0, 17.0)
	if move.length() > 0.1:
		hero_visual.rotation.y = atan2(-move.x, -move.z)
	hero_visual.position.y = sin(Time.get_ticks_msec() * 0.009) * 0.06 if move.length() > 0.1 else 0.0
	if guardian_hp > 0:
		enemy_attack -= delta
		var difference := hero.position - guardian.position
		if difference.length() > 2.5:
			guardian.position += difference.normalized() * delta * 2.3
		guardian_visual.look_at(hero.position + Vector3(0, 1.0, 0))
		if difference.length() <= 2.7 and enemy_attack <= 0:
			enemy_attack = 1.8
			if dodge_time <= 0:
				hp = maxf(0.0, hp - 12)
				_message("The guardian attacks! Dodge or strike back.")
				if hp <= 0:
					_end_game(false)
	elif hero.position.distance_to(swan_location) < 2.9:
		_end_game(true)
	camera.position = camera.position.lerp(hero.position + Vector3(12, 17, 19), minf(1, delta * 2.8))
	camera.look_at(hero.position + Vector3(0, 1.0, 0))
	light_beacon.light_energy = 1.6 + sin(Time.get_ticks_msec() * 0.002) * 0.4
	_update_ui()

func _attack() -> void:
	if game_over or puzzle_open or cooldown > 0:
		return
	cooldown = 0.52
	attack_time = 0.25
	if guardian_hp > 0 and hero.position.distance_to(guardian.position) < 3.4:
		guardian_hp = maxf(0.0, guardian_hp - 17)
		guardian_visual.scale = Vector3.ONE * 1.12
		_message("Sword hit! The guardian reels.")
		if guardian_hp == 0:
			_message("The guardian falls! Go to the four swans.")
	else:
		_message("Move closer to strike the guardian.")

func _dodge() -> void:
	if game_over or puzzle_open or cooldown > 0:
		return
	dodge_time = 0.85
	cooldown = 1.0
	_message("Dodge! You are briefly protected.")

func _rune_action() -> void:
	if game_over or puzzle_open:
		return
	if mana >= 3:
		if guardian_hp > 0 and hero.position.distance_to(guardian.position) < 9.0:
			guardian_hp = maxf(0.0, guardian_hp - 55)
			mana = 0
			_sphere(guardian.position + Vector3(0, 2.6, 0), Vector3(1.1, 1.1, 1.1), Color("#72dfff"), self, true)
			_message("WATER SURGE! Powerful rune magic strikes.")
			if guardian_hp == 0:
				_message("Guardian defeated! Rescue the Children of Lir.")
		else:
			_message("Move closer to the guardian before casting.")
		_update_ui()
		return
	puzzle_open = true
	rune_panel.visible = true
	_new_rune_board()

func _new_rune_board() -> void:
	rune_tiles.clear()
	for i in range(16):
		rune_tiles.append(random.randi_range(0, 3))
	selected = -1
	rune_moves = 7
	water_energy = 0
	_draw_runes()

func _draw_runes() -> void:
	for c in rune_grid.get_children():
		c.queue_free()
	for i in range(16):
		var slot := i
		var button := Button.new()
		button.text = GLYPHS[rune_tiles[i]]
		button.custom_minimum_size = Vector2(80, 67)
		if selected == i:
			button.modulate = Color("#ffda79")
		rune_grid.add_child(button)
		button.pressed.connect(func(): _choose_rune(slot))
	rune_status.text = "WATER %d/3  •  MOVES %d" % [water_energy, rune_moves]

func _choose_rune(index: int) -> void:
	if selected == -1:
		selected = index
		_draw_runes()
		return
	var from := selected
	selected = -1
	if absi(from % 4 - index % 4) + absi(from / 4 - index / 4) != 1:
		selected = index
		_draw_runes()
		return
	var old := rune_tiles.duplicate()
	rune_tiles[from] = old[index]
	rune_tiles[index] = old[from]
	var matched := _find_matches()
	if matched.is_empty():
		rune_tiles = old
		_draw_runes()
		return
	rune_moves -= 1
	for cell in matched:
		if rune_tiles[cell] == 0:
			water_energy += 1
		rune_tiles[cell] = random.randi_range(0, 3)
	if water_energy >= 3:
		mana = 3
		_close_runes()
		_message("Magic charged! Press RUNES close to the guardian.")
	elif rune_moves <= 0:
		_new_rune_board()
		_message("No moves left; a new rune board appears.")
	else:
		_draw_runes()
	_update_ui()

func _find_matches() -> Array[int]:
	var cells: Array[int] = []
	for y in range(4):
		for x in range(4):
			var index := y * 4 + x
			if x < 2 and rune_tiles[index] == rune_tiles[index + 1] and rune_tiles[index] == rune_tiles[index + 2]:
				for n in range(3):
					if not cells.has(index + n):
						cells.append(index + n)
			if y < 2 and rune_tiles[index] == rune_tiles[index + 4] and rune_tiles[index] == rune_tiles[index + 8]:
				for n in range(3):
					if not cells.has(index + n * 4):
						cells.append(index + n * 4)
	return cells

func _close_runes() -> void:
	puzzle_open = false
	rune_panel.visible = false

func _end_game(won: bool) -> void:
	game_over = true
	if won:
		_message("VICTORY! Fionnuala and the Children of Lir are reunited.")
	else:
		_message("DEFEAT! The guardian has prevailed. Restart to try again.")
	headline.text = "THE CHILDREN OF LIR — VICTORY!" if won else "THE GUARDIAN PREVAILS"
