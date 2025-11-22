extends Area3D

@export var duration: float = 5.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("apply_invincibility_powerup"):
		body.apply_invincibility_powerup(duration)
		queue_free()
