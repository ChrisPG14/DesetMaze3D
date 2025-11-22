extends CanvasLayer

@onready var _animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	Events.flag_reached.connect(func on_flag_reached() -> void:
		# Espera 2 segundos
		await get_tree().create_timer(2.0).timeout
		# Reproduce la animación de fade
		_animation_player.play("fade_in")
		# Espera a que termine la animación
		await _animation_player.animation_finished
		
		# --- CAMBIO AQUÍ ---
		# En lugar de salir, vamos a la pantalla de resultados
		get_tree().change_scene_to_file("res://EndScreen.tscn")
	)
