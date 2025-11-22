extends Control

const GAME_SCENE := preload("res://game.tscn")

@onready var difficulty_label: Label = $MenuContainer/DifficultyLabel

var difficulty_order: Array[String] = ["easy", "normal", "hard"]
var difficulty_names := {
	"easy": "Fácil",
	"normal": "Normal",
	"hard": "Difícil",
}
var difficulty_index: int = 1 # empieza en "normal"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_difficulty_label()

func _update_difficulty_label() -> void:
	var key: String = difficulty_order[difficulty_index]
	# Usamos get() por si acaso, para evitar errores
	difficulty_label.text = "Dificultad: " + str(difficulty_names.get(key, key))

func _on_Button_pressed() -> void:
	var key: String = difficulty_order[difficulty_index]
	Events.difficulty = key
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_packed(GAME_SCENE)

func _on_OptionsButton_pressed() -> void:
	difficulty_index = (difficulty_index + 1) % difficulty_order.size()
	var key: String = difficulty_order[difficulty_index]
	Events.difficulty = key
	_update_difficulty_label()

func _on_ExitButton_pressed() -> void:
	get_tree().quit()
