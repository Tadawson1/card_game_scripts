# File: res://game2.gd
extends Node2D

# ============================================
#                  CONSTANTS
# ============================================

const CARD_WIDTH: int = 140
const CARD_HEIGHT: int = 200
const DEBUG_MODE: bool = false  # Set to true to show test buttons

# ============================================
#                  VARIABLES
# ============================================

# Node References
@onready var card_library = $"../card_library"
@onready var deck = $"../deck"
@onready var hand = $"../hand"
@onready var gamemgr = $"../gamemgr"
@onready var discard = $"../discard"
@onready var effect_library = $"../effect_library"
@onready var scoreboard_manager = $"../scoreboard_manager"
@onready var card_display = $"../card_display"

# UI Elements
var new_game_button: Button
var top_card_button: Button
var bottom_card_button: Button

# Visual Elements (for game board)
var deck_visual: ColorRect
var hand_visual: ColorRect
var discard_visual: ColorRect
var active_area_visual: ColorRect

# Debug Elements
var test_urls_button: Button

#effect notifications
var effect_messages: Array = []

# ============================================
#              GODOT FUNCTIONS
# ============================================

func _ready():
	print("=== GAME2 SCENE READY ===")
	_verify_nodes()
	_create_menu_ui()
	
	if DEBUG_MODE:
		_create_debug_ui()


# ============================================
#            PUBLIC FUNCTIONS
#        (Called by other scripts)
# ============================================

func show_game_board():
	"""Shows the game board after starting a new game"""
	new_game_button.hide()
	_create_game_board()


func hide_card_choice_buttons():
	"""Hides the card choice buttons (called by gamemgr when not needed)"""
	if top_card_button:
		top_card_button.visible = false
	if bottom_card_button:
		bottom_card_button.visible = false


func show_card_choice_buttons():
	"""Shows the card choice buttons (called by gamemgr during draw phase)"""
	if top_card_button:
		top_card_button.visible = true
	if bottom_card_button:
		bottom_card_button.visible = true
		
func update_card_choice_buttons_for_return():
	"""Updates the card choice buttons for the return phase"""
	if top_card_button:
		top_card_button.text = "Return to Top"
		top_card_button.visible = true
	if bottom_card_button:
		bottom_card_button.text = "Return as 2nd"
		bottom_card_button.visible = true

func update_card_choice_buttons_for_draw():
	"""Resets the card choice buttons back to draw mode"""
	if top_card_button:
		top_card_button.text = "Draw Top"
	if bottom_card_button:
		bottom_card_button.text = "Draw Bottom"		
		
func show_card_movement(drawn_card_name: String, forced_card_name: String):
	"""Shows visual feedback of cards moving to hand and active area"""
	
	# Create a temporary label for the drawn card
	var drawn_label = Label.new()
	drawn_label.text = drawn_card_name + "\n→ TO HAND"
	drawn_label.position = Vector2(300, 300)
	drawn_label.add_theme_font_size_override("font_size", 24)
	drawn_label.add_theme_color_override("font_color", Color.GREEN)
	add_child(drawn_label)
	
	# Create a temporary label for the forced card
	var forced_label = Label.new()
	forced_label.text = forced_card_name + "\n→ FORCED PLAY"
	forced_label.position = Vector2(600, 300)
	forced_label.add_theme_font_size_override("font_size", 24)
	forced_label.add_theme_color_override("font_color", Color.RED)
	add_child(forced_label)
	
	# Remove labels after 2 seconds
	await get_tree().create_timer(5.0).timeout
	drawn_label.queue_free()
	forced_label.queue_free()
	
func show_effect_message(message: String, color: Color = Color.CYAN):
	"""Shows a temporary message for card effects"""
	var effect_label = Label.new()
	effect_label.text = message
	
	# Position messages below the card movement messages
	var y_offset = 500 + (effect_messages.size() * 40)  # Stack multiple messages
	effect_label.position = Vector2(400, y_offset)
	
	effect_label.add_theme_font_size_override("font_size", 20)
	effect_label.add_theme_color_override("font_color", color)
	add_child(effect_label)
	
	# Track this message
	effect_messages.append(effect_label)
	
	# Remove label after delay
	await get_tree().create_timer(3.0).timeout
	effect_messages.erase(effect_label)
	effect_label.queue_free()


# ============================================
#            PRIVATE FUNCTIONS
#            (Internal use only)
# ============================================

func _verify_nodes():
	"""Verifies all required nodes are present"""
	if not deck:
		print("ERROR: Deck not found!")
	if not gamemgr:
		print("ERROR: Game Manager not found!")
	if not hand:
		print("ERROR: Hand not found!")
	# Add other verifications as needed


func _create_menu_ui():
	"""Creates the main menu UI elements"""
	# New Game button
	new_game_button = Button.new()
	new_game_button.text = "New Game"
	new_game_button.size = Vector2(200, 60)
	new_game_button.position = Vector2(500, 300)  # Center of screen
	new_game_button.pressed.connect(_on_new_game_pressed)
	add_child(new_game_button)


func _create_game_board():
	"""Creates all the visual elements for the game board"""
	_create_deck_visual()
	_create_card_choice_buttons()
	_create_discard_visual()
	_create_active_area_visual()

func _create_deck_visual():
	"""Creates the deck visualization"""
	deck_visual = ColorRect.new()
	deck_visual.color = Color.YELLOW
	deck_visual.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	deck_visual.position = Vector2(1750, 600)
	add_child(deck_visual)
	
	# Add deck label
	var deck_label = Label.new()
	deck_label.text = "Deck"
	deck_label.position = Vector2(50, 90)
	deck_label.add_theme_color_override("font_color", Color.BLACK)
	deck_visual.add_child(deck_label)


func _create_card_choice_buttons():
	"""Creates the top and bottom card choice buttons"""
	# Top card button
	top_card_button = Button.new()
	top_card_button.text = "Draw Top"
	top_card_button.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	top_card_button.position = Vector2(1600, 600)
	top_card_button.pressed.connect(_on_top_card_pressed)
	add_child(top_card_button)
	
	# Bottom card button
	bottom_card_button = Button.new()
	bottom_card_button.text = "Draw Bottom"
	bottom_card_button.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	bottom_card_button.position = Vector2(1600, 850)
	bottom_card_button.pressed.connect(_on_bottom_card_pressed)
	add_child(bottom_card_button)
	


func _create_discard_visual():
	"""Creates the discard pile visualization"""
	discard_visual = ColorRect.new()
	discard_visual.color = Color.RED
	discard_visual.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	discard_visual.position = Vector2(1750, 850)
	add_child(discard_visual)
	
	# Add discard label
	var discard_label = Label.new()
	discard_label.text = "Discard"
	discard_label.position = Vector2(40, 90)
	discard_label.add_theme_color_override("font_color", Color.BLACK)
	discard_visual.add_child(discard_label)
	
	
func _create_active_area_visual():
	"""Creates the active/forced play area visualization"""
	active_area_visual = ColorRect.new()
	active_area_visual.color = Color.WHITE
	active_area_visual.size = Vector2(400,400)
	active_area_visual.position = Vector2(1300, 100)  
	add_child(active_area_visual)
	
	# Add active area label
	var active_label = Label.new()
	active_label.text = "Active/Forced"
	active_label.position = Vector2(20, 90)
	active_label.add_theme_color_override("font_color", Color.BLACK)
	active_area_visual.add_child(active_label)	
	

func _create_debug_ui():
	"""Creates debug UI elements (only in debug mode)"""
	test_urls_button = Button.new()
	test_urls_button.text = "Test Card URLs"
	test_urls_button.size = Vector2(200, 60)
	test_urls_button.position = Vector2(50, 50)
	test_urls_button.pressed.connect(_on_test_urls_pressed)
	test_urls_button.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent to show it's debug
	add_child(test_urls_button)


func _cleanup_game_board():
	"""Removes all game board elements (useful for restarting)"""
	var elements_to_remove = [
		deck_visual, hand_visual, discard_visual, 
		active_area_visual, top_card_button, bottom_card_button
	]
	
	for element in elements_to_remove:
		if element and is_instance_valid(element):
			element.queue_free()
	
	# Reset references
	deck_visual = null
	hand_visual = null
	discard_visual = null
	active_area_visual = null
	top_card_button = null
	bottom_card_button = null


# ============================================
#            SIGNAL CALLBACKS
# ============================================

func _on_new_game_pressed():
	"""Called when New Game button is pressed"""
	print("New Game button clicked!")
	
	if gamemgr:
		# Clean up any existing game board
		_cleanup_game_board()
		
		# Start new game
		gamemgr.start_new_game()
		
		# Show the game board
		show_game_board()
	else:
		print("ERROR: Game Manager not found!")


func _on_top_card_pressed():
	"""Called when top card button is pressed"""
	if gamemgr:
		gamemgr.player_chose_top_card()


func _on_bottom_card_pressed():
	"""Called when bottom card button is pressed"""
	if gamemgr:
		gamemgr.player_chose_bottom_card()


func _on_test_urls_pressed():
	"""Debug function to test card image URLs"""
	print("Starting URL tests...")
	if card_display:
		card_display.test_all_card_urls()
