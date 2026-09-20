extends CharacterBody2D

const Kecepatan = 300.0

var last_direction: Vector2 = Vector2.DOWN # arah hadap awal saat game mulai

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	process_movement()
	move_and_slide()

func process_movement() -> void:
	var direction := Input.get_vector("kiri", "kanan", "atas", "bawah")
	velocity = direction * Kecepatan

	if direction != Vector2.ZERO:
		last_direction = direction # simpan arah terakhir
		play_animation("walk", last_direction)
	else:
		play_animation("idle", last_direction) # idle pakai arah terakhir

func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(prefix + "_up")
	else:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(prefix + "_down")
