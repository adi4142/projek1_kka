extends CharacterBody2D

const Kecepatan = 300.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	process_movement()
	move_and_slide()
	
func process_movement() -> void:
	var direction := Input.get_vector("kiri","kanan","atas","bawah")
	
	if direction != Vector2.ZERO:
		velocity = direction * Kecepatan
	else:
		velocity = Vector2.ZERO
	
	# Kirim 'direction' yang sedang ditekan, bukan last_direction
	process_animation(direction)

func process_animation(direction: Vector2) -> void:
	if velocity != Vector2.ZERO:
		play_animation("run", direction)
	else:
		play_animation("idle", direction)

func play_animation(prefix: String, dir: Vector2) -> void:
	# Jika sedang diam, kita bisa pakai arah terakhir atau arah hadap terakhir jika mau,
	# tapi untuk idle biasanya cukup cek berdasarkan arah hadap sebelumnya.
	# Di sini kita tangani jika dir tidak zero (saat jalan) atau pakai arah default saat idle.
	
	if dir != Vector2.ZERO:
		if dir.x != 0:
			animated_sprite_2d.flip_h = dir.x < 0
			animated_sprite_2d.play(prefix + "_right")
		elif dir.y < 0:
			animated_sprite_2d.play(prefix + "_up")
		elif dir.y > 0:
			animated_sprite_2d.play(prefix + "_down")
	else:
		# Saat diam (velocity == ZERO), putar animasi idle berdasarkan prefix 
		# dengan mempertahankan arah hadap atau menggunakan animasi idle default
		animated_sprite_2d.play(prefix + "_down") # Sesuaikan dengan kebutuhan game kamu
