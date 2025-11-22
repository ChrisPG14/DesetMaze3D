extends Area3D

const ROTATION_SPEED = 180.0
@export var value: int = 1

@onready var pickup_sound: AudioStreamPlayer3D = $PickupSound
@onready var pickup_particles: GPUParticles3D = $PickupParticles
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	rotate_y(deg_to_rad(ROTATION_SPEED * delta))

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		body.collect_coin(value)

		# Efectos
		if pickup_sound:
			pickup_sound.play()
		if pickup_particles:
			pickup_particles.emitting = true

		# Escondemos la moneda y la borramos después de un pequeño delay
		if mesh:
			mesh.visible = false
		if $CollisionShape3D:
			$CollisionShape3D.disabled = true

		await get_tree().create_timer(0.4).timeout
		queue_free()
