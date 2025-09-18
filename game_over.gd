# File: res://game_over_screen.gd
extends Node2D  # Since you want Node2D

# Store the winner data
var winner_player: int = -1
var winner_stars: int = 0
var winner_condition: String = ""

func _ready():
	print("Game Over Screen loaded")
	
	# Read the winner data from the tree
	var tree = get_tree()
	if tree.has_meta("winner_player"):
		winner_player = tree.get_meta("winner_player")
		winner_stars = tree.get_meta("winner_stars")
		winner_condition = tree.get_meta("winner_condition", "")
		print("Got data - Player:", winner_player, " Stars:", winner_stars, " Condition:", winner_condition)
	else:
		print("No meta data found! Using defaults")
	
	# 🟢 CREATE EVERYTHING IN CODE
	_create_game_over_display()

func _create_game_over_display():
	# Create a new label from scratch
	var label = Label.new()
	
	# Build the text
	var text = "GAME OVER\n\n"
	if winner_player == -1:
		text += "It's a Tie!\n" + str(winner_stars) + " stars"
	else:
		text += "Player " + str(winner_player + 1) + " Wins!\n"
		text += str(winner_stars) + " stars\n"
		if winner_condition != "":
			text += "\nWin Condition: " + winner_condition
	
	label.text = text
	
	# Style the label
	label.add_theme_font_size_override("font_size", 60)
	label.add_theme_color_override("font_color", Color.RED)
	label.size = Vector2(800, 600)
	
	# Center it on screen
	var viewport_size = get_viewport().size
	label.position = Vector2(viewport_size.x / 2 - 400, viewport_size.y / 2 - 300)
	
	# Add to scene
	add_child(label)
	
	print("Created label with text:", text)
	print("At position:", label.position)
