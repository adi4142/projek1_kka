extends CharacterBody2D


const Kecepatan = 300.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	process_movement()
	move_and_slide()
	
func process_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("kiri","kanan","atas","bawah")
	
	velocity = direction * Kecepatan

func play_animation(dir: Vector2) -> void:
	if dir.x > 0:
		animated_sprite_2d.play("walk_right")
