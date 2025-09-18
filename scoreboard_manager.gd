# File: res://scoreboard_manager.gd
extends Node

# ============================================
#                  VARIABLES
# ============================================

# UI Elements (Labels)
var test_label: Label
var player1_label: Label
var player2_label: Label
var turn_label: Label
var current_player_label: Label
var player1_landmark_label: Label
var player2_landmark_label: Label
var player1_hand_size: int = 0  
var player2_hand_size: int = 0
var player1_hand_label: Label  
var player2_hand_label: Label

# Player Scores
var player1_score: int = 0
var player2_score: int = 0
var player1_landmarks: int = 0
var player2_landmarks: int = 0
var player1_wincon_label: Label
var player2_wincon_label: Label


var player1_win_condition: String = "Most Points"  # NEW: Default win condition
var player1_win_stars: int = 1  # NEW: Star rating for win condition
var player2_win_condition: String = "Most Points"  
var player2_win_stars: int = 1  


# Game State
var current_player: int = 0
var current_turn: int = 1


# ============================================
#              GODOT FUNCTIONS
# ============================================

func _ready():
	print("=== SCOREBOARD MANAGER: _ready() called ===")
	_create_all_labels()


# ============================================
#            PUBLIC FUNCTIONS
#    (Called by other scripts like gamemgr)
# ============================================

func update_player1_win_condition(condition_name: String, stars: int = 1):
	"""Updates Player 1's active win condition"""
	player1_win_condition = condition_name
	player1_win_stars = stars
	
	if player1_wincon_label != null:
		player1_wincon_label.text = "Win: " + condition_name + " (" + str(stars) + "★)"
	
	print("Player 1 win condition changed to: " + condition_name + " with " + str(stars) + " stars")

func update_player2_win_condition(condition_name: String, stars: int = 1):
	"""Updates Player 2's active win condition"""
	player2_win_condition = condition_name
	player2_win_stars = stars
	
	if player2_wincon_label != null:
		player2_wincon_label.text = "Win: " + condition_name + " (" + str(stars) + "★)"
	
	print("Player 2 win condition changed to: " + condition_name + " with " + str(stars) + " stars")
	
func get_player1_win_condition() -> Dictionary:
	"""Returns Player 1's current win condition and stars"""
	return {
		"condition": player1_win_condition,
		"stars": player1_win_stars
	}

func get_player2_win_condition() -> Dictionary:
	"""Returns Player 2's current win condition and stars"""
	return {
		"condition": player2_win_condition,
		"stars": player2_win_stars
	}

func get_both_win_conditions() -> Array:
	"""Returns both players' win conditions for easy comparison"""
	return [
		get_player1_win_condition(),
		get_player2_win_condition()
	]


func update_player_score(player_id: int, new_score: int):
	"""Updates the score for the specified player"""
	if player_id == 0:
		update_player1_score(new_score)
	elif player_id == 1:
		update_player2_score(new_score)
	else:
		print("ERROR: Invalid player_id: ", player_id)

func update_player_hand_size(player_id: int, hand_size: int):
	"""Updates the hand size for the specified player"""
	if player_id == 0:
		player1_hand_size = hand_size
		# 🟢 ADD: Update the visual label
		if player1_hand_label:
			player1_hand_label.text = "Hand: " + str(hand_size)
		print("Updated Player 1 hand size to: ", hand_size)
	elif player_id == 1:
		player2_hand_size = hand_size
		# 🟢 ADD: Update the visual label
		if player2_hand_label:
			player2_hand_label.text = "Hand: " + str(hand_size)
		print("Updated Player 2 hand size to: ", hand_size)
	else:
		print("ERROR: Invalid player_id for hand size: ", player_id)


func update_player1_score(new_score: int):
	"""Updates Player 1's score and display"""
	player1_score = new_score
	player1_label.text = "Player 1 Points: " + str(player1_score)
	print("Updated Player 1 score to: ", player1_score)


func update_player2_score(new_score: int):
	"""Updates Player 2's score and display"""
	player2_score = new_score
	player2_label.text = "Player 2 Points: " + str(player2_score)
	print("Updated Player 2 score to: ", player2_score)


func update_current_player(player_id: int):
	"""Updates which player's turn it is"""
	current_player = player_id
	
	# Only update label if it exists (in case called before _ready)
	if current_player_label != null:
		var player_name = "Player 1" if player_id == 0 else "Player 2"
		current_player_label.text = "Current: " + player_name
	
	print("Scoreboard: Current player is now Player ", (player_id + 1))


func update_turn(turn: int):
	"""Updates the turn counter (shows Player 1's turn count only)"""
	current_turn = turn
	var player1_turn_number = ((turn - 1) / 2) + 1
	turn_label.text = "Player 1 Turn: " + str(player1_turn_number)
	

func get_player_stat(player_id: int, stat_name: String) -> int:
	"""Gets a custom stat for a player (like landmarks)"""
	# For now, we only track landmarks as a custom stat
	if stat_name == "landmarks":
		# You'll need to add landmark tracking variables at the top:
		# var player1_landmarks: int = 0
		# var player2_landmarks: int = 0
		if player_id == 0:
			return player1_landmarks
		elif player_id == 1:
			return player2_landmarks
	
	print("WARNING: Unknown stat requested: " + stat_name)
	return 0


func set_player_stat(player_id: int, stat_name: String, value: int):
	"""Sets a custom stat for a player (like landmarks)"""
	if stat_name == "landmarks":
		if player_id == 0:
			player1_landmarks = value
			player1_landmark_label.text = "Landmarks: " + str(value) 
			# Optionally update a label if you have one
		elif player_id == 1:
			player2_landmarks = value
			player2_landmark_label.text = "Landmarks: " + str(value)
			# Optionally update a label if you have one
		print("Set Player " + str(player_id + 1) + " " + stat_name + " to " + str(value))
	else:
		print("WARNING: Trying to set unknown stat: " + stat_name)
		
		
		


# ============================================
#            PRIVATE FUNCTIONS
#        (Internal use only)
# ============================================

func _create_all_labels():
	"""Creates all UI labels for the scoreboard"""
	_create_test_label()
	_create_turn_label()
	_create_current_player_label()
	
	_create_player1_label()
	_create_player2_label()
	
	_create_player1_landmark_label()
	_create_player2_landmark_label()
	

	_create_player1_wincon_label()
	_create_player2_wincon_label()
	
	_create_player1_hand_label()
	_create_player2_hand_label()
	
func _create_test_label():
	"""Creates the red TEST label at the top"""
	test_label = Label.new()
	test_label.text = "SCORE: TEST"
	test_label.position = Vector2(250, 25)
	test_label.size = Vector2(200, 50)
	test_label.add_theme_color_override("font_color", Color.RED)
	test_label.add_theme_font_size_override("font_size", 30)
	add_child(test_label)
	
func _create_turn_label():
	"""Creates the turn counter display"""
	turn_label = Label.new()
	turn_label.text = "Player 1 Turn: 1"
	turn_label.position = Vector2(800, 100)
	turn_label.size = Vector2(200, 50)
	turn_label.add_theme_color_override("font_color", Color.YELLOW)
	turn_label.add_theme_font_size_override("font_size", 20)
	add_child(turn_label)	
	
func _create_current_player_label():
	"""Creates the current player indicator"""
	current_player_label = Label.new()
	current_player_label.text = "Current: Player 1"
	current_player_label.position = Vector2(800, 150)
	current_player_label.size = Vector2(200, 50)
	current_player_label.add_theme_color_override("font_color", Color.GREEN)
	current_player_label.add_theme_font_size_override("font_size", 20)
	add_child(current_player_label)	

func _create_player1_label():
	"""Creates Player 1's score display"""
	player1_label = Label.new()
	player1_label.text = "Player 1: 0"
	player1_label.position = Vector2(100, 100)
	player1_label.size = Vector2(200, 50)
	player1_label.add_theme_color_override("font_color", Color.WHITE)
	player1_label.add_theme_font_size_override("font_size", 20)
	add_child(player1_label)
	
func _create_player1_landmark_label():
	"""Creates Player 1's landmark display"""
	player1_landmark_label = Label.new()
	player1_landmark_label.text = "Landmarks: 0"
	player1_landmark_label.position = Vector2(100, 150)  # To the right of score
	player1_landmark_label.size = Vector2(150, 50)
	player1_landmark_label.add_theme_color_override("font_color", Color.CYAN)
	player1_landmark_label.add_theme_font_size_override("font_size", 16)
	add_child(player1_landmark_label)


func _create_player1_wincon_label():
	"""Creates Player 1's win condition display"""
	player1_wincon_label = Label.new()
	player1_wincon_label.text = "Active Win-Con: Most Points (1★)"  # Default
	player1_wincon_label.position = Vector2(100, 200)  # Below landmarks
	player1_wincon_label.size = Vector2(250, 50)
	player1_wincon_label.add_theme_color_override("font_color", Color.GOLD)
	player1_wincon_label.add_theme_font_size_override("font_size", 16)
	add_child(player1_wincon_label)	
	
func _create_player1_hand_label():
	"""Creates Player 1's hand size display"""
	player1_hand_label = Label.new()
	player1_hand_label.text = "Hand: 3"  # Starts with 3 cards
	player1_hand_label.position = Vector2(100, 125)  # Between score and landmarks
	player1_hand_label.size = Vector2(150, 50)
	player1_hand_label.add_theme_color_override("font_color", Color.YELLOW)
	player1_hand_label.add_theme_font_size_override("font_size", 16)
	add_child(player1_hand_label)	


func _create_player2_label():
	"""Creates Player 2's score display"""
	player2_label = Label.new()
	player2_label.text = "Player 2: 0"
	player2_label.position = Vector2(500, 100)
	player2_label.size = Vector2(200, 50)
	player2_label.add_theme_color_override("font_color", Color.WHITE)
	player2_label.add_theme_font_size_override("font_size", 20)
	add_child(player2_label)
	
func _create_player2_landmark_label():
	"""Creates Player 2's landmark display"""
	player2_landmark_label = Label.new()
	player2_landmark_label.text = "Landmarks: 0"
	player2_landmark_label.position = Vector2(500, 150)  # Below Player 2's score
	player2_landmark_label.size = Vector2(150, 50)
	player2_landmark_label.add_theme_color_override("font_color", Color.CYAN)
	player2_landmark_label.add_theme_font_size_override("font_size", 16)
	add_child(player2_landmark_label)
	
func _create_player2_wincon_label():
	"""Creates Player 2's win condition display"""
	player2_wincon_label = Label.new()
	player2_wincon_label.text = "Active Win-Con: Most Points (1★)"  # Default
	player2_wincon_label.position = Vector2(500, 200)  # Below Player 2's landmarks
	player2_wincon_label.size = Vector2(250, 50)
	player2_wincon_label.add_theme_color_override("font_color", Color.GOLD)
	player2_wincon_label.add_theme_font_size_override("font_size", 16)
	add_child(player2_wincon_label)
	
func _create_player2_hand_label():
	"""Creates Player 2's hand size display"""
	player2_hand_label = Label.new()
	player2_hand_label.text = "Hand: 3"  # Starts with 3 cards
	player2_hand_label.position = Vector2(500, 125)  # Between score and landmarks
	player2_hand_label.size = Vector2(150, 50)
	player2_hand_label.add_theme_color_override("font_color", Color.YELLOW)
	player2_hand_label.add_theme_font_size_override("font_size", 16)
	add_child(player2_hand_label)	
