## ProceduralDungeon.gd  (v2 — Chain-based, terarah & rapi)
## Setiap kamar hanya punya 1–2 koneksi:
##   - Main path : START → kamar1 → kamar2 → ... → EXIT  (masing-masing max 2 pintu)
##   - Branch    : dead-end opsional (1 pintu saja)
##
## Cara pakai sama seperti v1.

extends Node2D

# ─────────────────────────────────────────────
# KONFIGURASI
# ─────────────────────────────────────────────
const TILE_FLOOR := Vector2i(37, 1)
const TILE_WALL  := Vector2i(44, 7)
const TILE_EXIT  := Vector2i(2, 0)   # ← ganti sesuai tile "pintu exit" di atlas kamu
const SOURCE_ID  := 0

@export var room_min        : int = 6    # ukuran kamar minimum (tile)
@export var room_max        : int = 11   # ukuran kamar maksimum (tile)
@export var room_count      : int = 10   # jumlah kamar di main path
@export var branch_count    : int = 2    # kamar dead-end di luar main path
@export var corridor_min    : int = 2    # panjang koridor minimum (tile)
@export var corridor_max    : int = 5    # panjang koridor maksimum (tile)
@export var seed_value      : int = 0    # 0 = acak tiap run

@export var player_scene    : PackedScene
@export var exit_scene      : PackedScene

# ─────────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────────
var _rng      := RandomNumberGenerator.new()
var _map      := {}           # Dictionary[Vector2i, bool] — hanya simpan tile lantai
var _all_rooms: Array[Rect2i] = []
var _main_path_count : int = 0  # berapa kamar yang masuk main path
var _exit_door_tile  : Vector2i = Vector2i.ZERO  # posisi tile pintu exit

@onready var _tilemap : TileMapLayer = $TileMapLayer

# ─────────────────────────────────────────────
func _ready() -> void:
	generate()


## Generate ulang dungeon. Panggil kapanpun untuk level baru.
func generate(custom_seed: int = seed_value) -> void:
	_rng.seed = custom_seed if custom_seed != 0 else int(Time.get_unix_time_from_system())
	_map.clear()
	_all_rooms.clear()
	_main_path_count = 0
	_exit_door_tile  = Vector2i.ZERO

	_build_main_path()
	_add_branches()
	_paint_tilemap()
	_paint_exit_door()   # harus setelah _paint_tilemap
	_place_start_exit()


# ─────────────────────────────────────────────
# STEP 1 — Bangun rantai utama (main path)
# Setiap kamar terhubung hanya ke tetangga sebelum & sesudahnya.
# ─────────────────────────────────────────────
func _build_main_path() -> void:
	# Kamar pertama di posisi 0,0
	var first := _random_room()
	first.position = Vector2i(0, 0)
	_all_rooms.append(first)
	_carve_room(first)

	var prev := first

	for _i in range(1, room_count):
		var next := _place_next_to(prev)
		if next == Rect2i():
			break   # tidak ada tempat kosong, berhenti
		_all_rooms.append(next)
		_carve_room(next)
		_carve_corridor(prev, next)
		prev = next

	_main_path_count = _all_rooms.size()


# ─────────────────────────────────────────────
# STEP 2 — Tambah dead-end branch (opsional)
# Branch hanya punya 1 pintu → tidak mempengaruhi alur utama.
# ─────────────────────────────────────────────
func _add_branches() -> void:
	# Ambil kamar di tengah main path sebagai kandidat (hindari START & EXIT)
	var candidates : Array[int] = []
	for i in range(1, _main_path_count - 1):
		candidates.append(i)
	_shuffle(candidates)

	var added := 0
	for ci in candidates:
		if added >= branch_count:
			break
		var branch := _place_next_to(_all_rooms[ci])
		if branch != Rect2i():
			_all_rooms.append(branch)
			_carve_room(branch)
			_carve_corridor(_all_rooms[ci], branch)
			added += 1


# ─────────────────────────────────────────────
# Coba taruh kamar baru bersebelahan dengan `from_room`
# Acak urutan 4 arah supaya tidak monoton tapi tetap terstruktur.
# ─────────────────────────────────────────────
func _place_next_to(from_room: Rect2i) -> Rect2i:
	var dirs := [0, 1, 2, 3]   # kanan, bawah, kiri, atas
	_shuffle(dirs)

	for dir in dirs:
		var gap     := _rng.randi_range(corridor_min, corridor_max)
		var new_rm  := _random_room()

		match dir:
			0:  # kanan
				new_rm.position.x = from_room.end.x + gap
				new_rm.position.y = from_room.get_center().y - int(new_rm.size.y / 2)
			1:  # bawah
				new_rm.position.x = from_room.get_center().x - int(new_rm.size.x / 2)
				new_rm.position.y = from_room.end.y + gap
			2:  # kiri
				new_rm.position.x = from_room.position.x - new_rm.size.x - gap
				new_rm.position.y = from_room.get_center().y - int(new_rm.size.y / 2)
			3:  # atas
				new_rm.position.x = from_room.get_center().x - int(new_rm.size.x / 2)
				new_rm.position.y = from_room.position.y - new_rm.size.y - gap

		if not _overlaps_any(new_rm):
			return new_rm

	return Rect2i()   # semua arah terblokir


func _random_room() -> Rect2i:
	var w := _rng.randi_range(room_min, room_max)
	var h := _rng.randi_range(room_min, room_max)
	return Rect2i(0, 0, w, h)


func _overlaps_any(room: Rect2i) -> bool:
	var padded := room.grow(2)   # margin 2 tile antar kamar
	for r in _all_rooms:
		if padded.intersects(r):
			return true
	return false


# ─────────────────────────────────────────────
# Ukir lantai kamar ke _map
# ─────────────────────────────────────────────
func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			_map[Vector2i(x, y)] = true


# ─────────────────────────────────────────────
# Koridor L-shape 2 tile lebar antara dua kamar
# ─────────────────────────────────────────────
func _carve_corridor(room_a: Rect2i, room_b: Rect2i) -> void:
	var a := room_a.get_center()
	var b := room_b.get_center()

	# Horizontal dulu dari a ke b.x, lalu vertikal
	var sx := 1 if b.x >= a.x else -1
	for x in range(a.x, b.x + sx, sx):
		_map[Vector2i(x, a.y)]     = true
		_map[Vector2i(x, a.y + 1)] = true

	var sy := 1 if b.y >= a.y else -1
	for y in range(a.y, b.y + sy, sy):
		_map[Vector2i(b.x,     y)] = true
		_map[Vector2i(b.x + 1, y)] = true


# ─────────────────────────────────────────────
# Paint TileMapLayer
# Lantai → TILE_FLOOR, sekitar lantai → TILE_WALL
# ─────────────────────────────────────────────
func _paint_tilemap() -> void:
	_tilemap.clear()

	for coord: Vector2i in _map.keys():
		_tilemap.set_cell(coord, SOURCE_ID, TILE_FLOOR)
		# Cat dinding di sekeliling tile lantai
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nb : Vector2i = coord + Vector2i(dx, dy)
				if not _map.has(nb):
					_tilemap.set_cell(nb, SOURCE_ID, TILE_WALL)


# ─────────────────────────────────────────────
# Buat pintu exit di dinding kamar terakhir
# Arah pintu = sisi berlawanan dari arah datang
# Lorong pendek 3 tile ke luar supaya keliatan jelas
# ─────────────────────────────────────────────
func _paint_exit_door() -> void:
	if _main_path_count < 2:
		return

	var last_room : Rect2i = _all_rooms[_main_path_count - 1]
	var prev_room : Rect2i = _all_rooms[_main_path_count - 2]
	var last_c    := last_room.get_center()
	var prev_c    := prev_room.get_center()
	var diff      := last_c - prev_c

	# Tentukan arah keluar (berlawanan dari arah masuk)
	# door_base  = tile dinding yang akan jadi pintu
	# out_dir    = arah vektor keluar (1 tile per step)
	var door_base : Vector2i
	var out_dir   : Vector2i
	var side_dir  : Vector2i   # arah samping untuk lebar 2 tile

	if abs(diff.x) >= abs(diff.y):
		# Datang secara horizontal
		if diff.x > 0:
			# Datang dari kiri → exit di dinding KANAN
			door_base = Vector2i(last_room.end.x,     last_c.y)
			out_dir   = Vector2i(1, 0)
			side_dir  = Vector2i(0, 1)
		else:
			# Datang dari kanan → exit di dinding KIRI
			door_base = Vector2i(last_room.position.x - 1, last_c.y)
			out_dir   = Vector2i(-1, 0)
			side_dir  = Vector2i(0, 1)
	else:
		# Datang secara vertikal
		if diff.y > 0:
			# Datang dari atas → exit di dinding BAWAH
			door_base = Vector2i(last_c.x, last_room.end.y)
			out_dir   = Vector2i(0, 1)
			side_dir  = Vector2i(1, 0)
		else:
			# Datang dari bawah → exit di dinding ATAS
			door_base = Vector2i(last_c.x, last_room.position.y - 1)
			out_dir   = Vector2i(0, -1)
			side_dir  = Vector2i(1, 0)

	# Taruh TILE_EXIT di lubang dinding (2 tile lebar)
	_tilemap.set_cell(door_base,            SOURCE_ID, TILE_EXIT)
	_tilemap.set_cell(door_base + side_dir, SOURCE_ID, TILE_EXIT)
	_exit_door_tile = door_base

	# Carve lorong pendek keluar (3 tile) supaya exit terlihat
	for step in range(1, 4):
		var t1 : Vector2i = door_base            + out_dir * step
		var t2 : Vector2i = door_base + side_dir + out_dir * step
		_tilemap.set_cell(t1, SOURCE_ID, TILE_FLOOR)
		_tilemap.set_cell(t2, SOURCE_ID, TILE_FLOOR)
		# Dinding samping lorong exit
		_tilemap.set_cell(t1 - side_dir, SOURCE_ID, TILE_WALL)
		_tilemap.set_cell(t2 + side_dir, SOURCE_ID, TILE_WALL)

	print("  Exit door  : tile %s, arah %s" % [str(_exit_door_tile), str(out_dir)])


# ─────────────────────────────────────────────
# Spawn START & EXIT
# START = kamar pertama di main path
# EXIT  = kamar terakhir di main path
# ─────────────────────────────────────────────
func _place_start_exit() -> void:
	if _all_rooms.is_empty():
		push_warning("ProceduralDungeon: Tidak ada kamar!")
		return

	var start_tile := _all_rooms[0].get_center()
	var exit_tile  := _all_rooms[_main_path_count - 1].get_center()
	var start_pos  := _tilemap.map_to_local(start_tile)
	var exit_pos   := _tilemap.map_to_local(exit_tile)

	if player_scene:
		var p = player_scene.instantiate()
		p.global_position = start_pos
		get_parent().add_child.call_deferred(p)
	else:
		_spawn_marker(start_pos, Color.GREEN, "START")

	if exit_scene:
		var e = exit_scene.instantiate()
		e.global_position = exit_pos
		get_parent().add_child.call_deferred(e)
	else:
		_spawn_marker(exit_pos, Color.RED, "EXIT")

	print("=== Dungeon Generated ===")
	print("  Seed       : ", _rng.seed)
	print("  Main path  : %d kamar" % _main_path_count)
	print("  Branches   : %d kamar" % (_all_rooms.size() - _main_path_count))
	print("  START tile : ", start_tile)
	print("  EXIT tile  : ", exit_tile)


func _spawn_marker(pos: Vector2, color: Color, label: String) -> void:
	var node := Node2D.new()
	node.name = label
	node.global_position = pos

	var rect := ColorRect.new()
	rect.size    = Vector2(16, 16)
	rect.position = Vector2(-8, -8)
	rect.color   = color
	node.add_child(rect)

	var lbl := Label.new()
	lbl.text     = label
	lbl.position = Vector2(-12, -26)
	lbl.add_theme_font_size_override("font_size", 10)
	node.add_child(lbl)

	get_parent().add_child.call_deferred(node)


# ─────────────────────────────────────────────
# UTILITY
# ─────────────────────────────────────────────

## Posisi world titik awal
func get_start_world_pos() -> Vector2:
	if _all_rooms.is_empty(): return Vector2.ZERO
	return _tilemap.map_to_local(_all_rooms[0].get_center())

## Posisi world titik akhir (di pintu exit)
func get_exit_world_pos() -> Vector2:
	if _all_rooms.is_empty(): return Vector2.ZERO
	return _tilemap.map_to_local(_exit_door_tile)

## Posisi world center kamar exit
func get_exit_room_center() -> Vector2:
	if _all_rooms.is_empty(): return Vector2.ZERO
	return _tilemap.map_to_local(_all_rooms[_main_path_count - 1].get_center())

## Center semua kamar (berguna untuk spawn musuh, item, dll.)
## Index 0 = START, index main_path_count-1 = EXIT, sisanya = branch
func get_room_centers() -> Array[Vector2]:
	var result : Array[Vector2] = []
	for r in _all_rooms:
		result.append(_tilemap.map_to_local(r.get_center()))
	return result

## Jumlah kamar di main path
func get_main_path_count() -> int:
	return _main_path_count


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
