extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var score_label = $VBoxContainer/ScoreLabel

# Variables estáticas para pasar datos entre escenas (Truco rápido)
static var is_win = false
static var final_score = 0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Asegurar que se vea el mouse
	
	# Configurar textos según si ganó o perdió
	if is_win:
		title_label.text = "¡VICTORIA!"
		title_label.modulate = Color.GREEN # Texto verde
	else:
		title_label.text = "GAME OVER"
		title_label.modulate = Color.RED # Texto rojo
		
	score_label.text = "Puntaje Final: " + str(final_score)

# Conecta esta señal desde el editor al botón RestartButton
func _on_restart_button_pressed():
	get_tree().change_scene_to_file("res://game.tscn") # Tu escena de juego

# Conecta esta señal desde el editor al botón MenuButton
func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://menu.tscn") # Tu menú principal
