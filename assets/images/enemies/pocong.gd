extends CharacterBody2D

@export var speed: float = 100.0
@export var detection_radius: float = 200.0
@export var attack_radius: float = 30.0

@export var Player: Node2D 

func _ready() -> void:
	# Mencari node player berdasarkan kelompok (Group)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		Player = players[0]

func _physics_process(_delta: float) -> void:
	if not Player:
		return

	var distance = global_position.distance_to(Player.global_position)

	# State 1: Mengejar Pemain
	if distance <= detection_radius and distance > attack_radius:
		var direction = (Player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	
	# State 2: Menyerang Pemain
	elif distance <= attack_radius:
		velocity = Vector2.ZERO
		attack()
	
	# State 3: Diam / Idle
	else:
		velocity = Vector2.ZERO

func attack() -> void:
	# Tambahkan logika serangan di sini (misal: kurangi HP player atau putar animasi)
	print("Musuh menyerang pemain!")
