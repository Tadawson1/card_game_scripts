# File: res://gamemgr.gd
extends Node

# ============================================
#                ENUMS & CONSTANTS
# ============================================

enum GamePhase { 
	DRAW, 
	FORCED_PLAY, 
	HAND_PLAY, 
	EFFECT_RESOLUTION, 
	CLEANUP 
}

const MAX_TURNS: int = 4
const STARTING_HAND_SIZE: int = 3
const AI_DELAY: float = 3.0  # Delay for AI decisions (in seconds)

# ============================================
#                  VARIABLES
# ============================================

# Node References
@onready var deck = $"../deck"
@onready var hand = $"../hand"
@onready var discard = $"../discard"
@onready var active_card_area = $"../active_card_area"
@onready var effect_library = $"../effect_library"
@onready var card_display = $"../card_display"
@onready var scoreboard_manager = $"../scoreboard_manager"
@onready var game2_node = $"../Node2D" 

# Game State
var current_player: int = 0  # 0 = Player 1, 1 = Player 2 (AI)
var current_phase: GamePhase = GamePhase.DRAW
var turn_count: int = 0

# UI Elements (created dynamically)
var target_self_button: Button
var target_opponent_button: Button
var game_over_label: Label
var game_over_panel: Panel



# ============================================
#              GODOT FUNCTIONS
# ============================================

func _ready():
	print("Game Manager initialized")
	_create_target_buttons()

# ============================================
#            PUBLIC FUNCTIONS
#           (Called by other scripts)
# ============================================


func start_new_game():
	"""Initializes a new game"""
	# Reset game state
	current_player = 0
	current_phase = GamePhase.DRAW
	turn_count = 0
	
	# Setup deck and deal starting hands
	deck.start_new_game()

	for i in range(STARTING_HAND_SIZE):
		# Player 1's starting hand
		if not deck.is_empty():
			var card1 = deck.draw_top_card()
			if card1:
				hand.add_card_for_player(card1, 0)
		
		# Player 2's starting hand
		if not deck.is_empty():
			var card2 = deck.draw_top_card()
			if card2:
				hand.add_card_for_player(card2, 1)
				
	hand._refresh_hand_display()			
	
	scoreboard_manager.update_player_hand_size(0, hand.get_hand_size_for_player(0))
	scoreboard_manager.update_player_hand_size(1, hand.get_hand_size_for_player(1))	

	
	print("=== GAME MANAGER: Game Ready ===")
	_print_game_state()
	
	# Update scoreboard
	scoreboard_manager.update_current_player(current_player)
	scoreboard_manager.update_turn(turn_count + 1)
	
	# Start first turn
	_handle_ai_turn()
	

func player_chose_top_card():
	"""Handles when player chooses to draw the top card"""
	if current_phase != GamePhase.DRAW:
		print("ERROR: Not in draw phase!")
		return
	
	print("GameManager: Player chose TOP CARD")
	_process_card_choice(true)  # true = top card


func player_chose_bottom_card():
	"""Handles when player chooses to draw the bottom card"""
	if current_phase != GamePhase.DRAW:
		print("ERROR: Not in draw phase!")
		return
	
	print("GameManager: Player chose BOTTOM CARD")
	_process_card_choice(false)  # false = bottom card


func play_hand_card(card_index: int):
	"""Plays a card from the player's hand"""
	if current_phase != GamePhase.HAND_PLAY:
		print("ERROR: Not in hand play phase!")
		return
	
	if card_index < 0 or card_index >= hand.get_hand_size_for_player(current_player):
		print("ERROR: Invalid card index!")
		return
	
	var hand_card = hand.remove_card_for_player(card_index, current_player)
	if hand_card == null:
		print("ERROR: Failed to remove card from hand!")
		return
		
		#update hand size scoreboard after card is played
	scoreboard_manager.update_player_hand_size(current_player, hand.get_hand_size_for_player(current_player))		
	
	# Add hand card to active area
	active_card_area.add_card(hand_card)
	
	if card_display:
		card_display.load_forced_card_image(hand_card.name)
	
	# Move to effect resolution phase
	current_phase = GamePhase.EFFECT_RESOLUTION
	_print_game_state()
	
	if _is_win_condition_card(hand_card):
		print("Win condition card played! Processing immediately...")
		_process_win_condition_card(hand_card)
	else:
		print("Waiting for target selection...")
		# Show target selection buttons for normal cards
		_show_target_buttons()	


func process_hand_card_effects_on_self():
	"""Processes the played hand card's effects targeting the current player"""
	print("=== PROCESSING HAND CARD EFFECTS ON SELF ===")
	_process_active_card_effects(current_player)
	_cleanup_turn()

func _check_game_end() -> bool:
	"""Checks if the game should end"""
	if turn_count >= (MAX_TURNS * 2):
		print("Maximum turns reached!")
		return true
	
	# Add other end conditions here (deck empty, special win conditions, etc.)
	
	return false

func process_hand_card_effects_on_opponent():
	"""Processes the played hand card's effects targeting the opponent"""
	print("=== PROCESSING HAND CARD EFFECTS ON OPPONENT ===")
	var opponent_player = (current_player + 1) % 2
	_process_active_card_effects(opponent_player)
	_cleanup_turn()


# ============================================
#            PRIVATE FUNCTIONS
#            (Internal use only)
# ============================================

func _create_target_buttons():
	"""Creates the target selection buttons (hidden initially)"""
	# Target Self button
	target_self_button = Button.new()
	target_self_button.text = "Target Self"
	target_self_button.size = Vector2(200, 60)
	target_self_button.position = Vector2(300, 200)
	target_self_button.visible = false
	target_self_button.pressed.connect(_on_target_self_pressed)
	add_child(target_self_button)
	
	# Target Opponent button
	target_opponent_button = Button.new()
	target_opponent_button.text = "Target Opponent"
	target_opponent_button.size = Vector2(200, 60)
	target_opponent_button.position = Vector2(520, 200)
	target_opponent_button.visible = false
	target_opponent_button.pressed.connect(_on_target_opponent_pressed)
	add_child(target_opponent_button)
	

func _process_card_choice(chose_top: bool):
	"""Handles the card draw choice and forced play"""
	# Draw both cards
	var top_card = deck.draw_top_card()
	var bottom_card = deck.draw_top_card()  # Second card drawn is "bottom"
	
	var drawn_card
	var forced_card
	
	if chose_top:
		drawn_card = top_card      # Chose top, keep top
		forced_card = bottom_card   # Force play bottom
	else:
		drawn_card = bottom_card    # Chose bottom, keep bottom  
		forced_card = top_card      # Force play top
	
	print("Chose to draw: " + drawn_card.name)
	print("FORCED to play: " + forced_card.name)
	
	if game2_node and game2_node.has_method("show_card_movement"):
		game2_node.show_card_movement(drawn_card.name, forced_card.name)		
	
	
	# Add chosen card to current player's hand
	hand.add_card_for_player(drawn_card, current_player)
	
	# Update hand size for the current player
	scoreboard_manager.update_player_hand_size(current_player, hand.get_hand_size_for_player(current_player))
	
	# Process forced card
	_process_forced_card(forced_card)
	
	# Move to hand play phase
	current_phase = GamePhase.FORCED_PLAY
	_print_game_state()
	_advance_to_hand_play()


func _process_forced_card(card):
	"""Processes the forced card's effects and discards it"""
	print("=== PROCESSING FORCED CARD EFFECTS ===")
	active_card_area.add_card(card)
	
	if card_display:
		card_display.load_forced_card_image(card.name)	
	
	if _is_win_condition_card(card):
		print("Forced card is a win condition! Applying to current player...")
		_process_win_condition_card(card)
	else:
		# Process normal effects for forced card
		print("Processing effects for forced card: " + card.name)
		# Process on current player by default for forced cards
		_process_single_card_effects(card, current_player)	
	

	# Move forced card to discard
	var cards_to_discard = active_card_area.clear_all_cards()
	for discard_card in cards_to_discard:
		discard.add_card(discard_card)
	
	print("=== FORCED CARD EFFECTS COMPLETE ===")


func _advance_to_hand_play():
	"""Advances the game to the hand play phase"""
	print("=== ADVANCING TO HAND PLAY PHASE ===")
	current_phase = GamePhase.HAND_PLAY
	_print_game_state()
	print("Player must now choose a card from hand to play")
	
	if current_player == 1:
		_ai_play_hand_card()	
	
func _is_win_condition_card(card) -> bool:
	"""Checks if a card has win condition effects"""
	if not card.has("effects"):
		return false
	
	for effect in card.effects:
		if effect.begins_with("win_condition"):
			return true
	
	return false
	
	#process win condition cards
func _process_win_condition_card(card):
	"""Processes win condition cards (always applies to the player who played it)"""
	print("Processing win condition card: " + card.name)
	
	# Win conditions always apply to the player who played them
	_process_single_card_effects(card, current_player)
	
	# No need for target selection, go straight to cleanup
	_cleanup_turn()
	
func _process_single_card_effects(card, target_player: int):
	"""Processes all effects of a single card"""
	# Process point value if it has one
	if card.has("points") and card.points != 0:
		print("Card has " + str(card.points) + " points")
		effect_library.apply_effect("add_points", target_player, current_player, {"amount": card.points})
	
	if card.has("effects"):
		print("Card effects: ", card.effects)
		for effect in card.effects:
			effect_library.apply_effect(effect, target_player, current_player)
	

func _process_active_card_effects(target_player: int):
	"""Processes all active card effects targeting the specified player"""
	for card in active_card_area.active_cards:
		print("Processing effects for: " + card.name + " (targeting Player " + str(target_player + 1) + ")")
		_process_single_card_effects(card,target_player)
		print("Card effects complete")


func _cleanup_turn():
	"""Cleans up the current turn and prepares for the next"""
	print("=== CLEANUP PHASE ===")
	current_phase = GamePhase.CLEANUP
	_print_game_state()
	
	# Hide target buttons
	_hide_target_buttons()
	
	# Move all active cards to discard
	var cards_to_discard = active_card_area.clear_all_cards()
	for card in cards_to_discard:
		discard.add_card(card)
	
	# Switch to next player and increment turn
	current_player = (current_player + 1) % 2
	turn_count += 1
	
	# Update scoreboard
	scoreboard_manager.update_current_player(current_player)
	scoreboard_manager.update_turn(turn_count + 1)
	
		# Check for game end
	if _check_game_end():
		_end_game()
		return
		
	# Return to draw phase for next turn
	current_phase = GamePhase.DRAW
	_print_game_state()
	print("=== TURN COMPLETE - Next player's turn ===")
	
	_handle_ai_turn()
	
func _end_game():
	"""Handles game ending"""
	print("=== GAME OVER ===")
	print("Final turn count: " + str(turn_count))
	
	var p1_stars = _calculate_player_stars(0)
	var p2_stars = _calculate_player_stars(1)
	
	print("FINAL STARS:")
	print("  Player 1: " + str(p1_stars) + " stars")
	print("  Player 2: " + str(p2_stars) + " stars")
	
	# Determine winner and prepare data
	var winner_player = -1  # -1 means tie
	var winner_stars = 0
	var winner_condition = ""	
	
	if p1_stars > p2_stars:
		winner_player = 0
		winner_stars = p1_stars
		var wincon_data = scoreboard_manager.get_player1_win_condition()
		winner_condition = wincon_data.condition
		print("WINNER: Player 1 wins with " + str(p1_stars) + " stars!")
	elif p2_stars > p1_stars:
		winner_player = 1
		winner_stars = p2_stars
		var wincon_data = scoreboard_manager.get_player2_win_condition()
		winner_condition = wincon_data.condition
		print("WINNER: Player 2 wins with " + str(p2_stars) + " stars!")
	else:
		winner_stars = p1_stars  # Both have same
		print("GAME ENDED IN A TIE! Both players have " + str(p1_stars) + " stars")
		
	var tree = get_tree()
	tree.set_meta("winner_player", winner_player)
	tree.set_meta("winner_stars", winner_stars)
	tree.set_meta("winner_condition", winner_condition)
	
	print("Stored in tree meta - Winner: " + str(winner_player) + ", Stars: " + str(winner_stars) + ", Condition: " + winner_condition)	
		
	var game_over_scene = load("res://game_over.tscn")  
	
	if game_over_scene == null:
		print("ERROR: Could not load game_over_screen.tscn")
		return
		
	var game_over_instance = game_over_scene.instantiate()
	
	
	get_tree().root.add_child(game_over_instance)
	# Remove the current scene
	var current = get_tree().current_scene
	if current:
		current.queue_free()
	# Set the new scene as current
	get_tree().current_scene = game_over_instance	

func _calculate_player_stars(player_id: int) -> int:
	"""Calculates how many stars a player earned based on their win condition"""
	
	var wincon_data
	if player_id == 0:
		wincon_data = scoreboard_manager.get_player1_win_condition()
	else:
		wincon_data = scoreboard_manager.get_player2_win_condition()
	
	var condition = wincon_data.condition
	var potential_stars = wincon_data.stars
	
	print("Player " + str(player_id + 1) + " has win condition: " + condition + " (worth " + str(potential_stars) + " stars if met)")
	
	# Check if they met their win condition
	var condition_met = _check_win_condition_met(player_id, condition)
	
	print("  -> Checking condition '" + condition + "' for Player " + str(player_id + 1))
	print("  -> Condition met? " + str(condition_met))
	
	if condition_met:
		print("  -> Condition MET! Earned " + str(potential_stars) + " stars")
		return potential_stars
	else:
		print("  -> Condition NOT met. Earned 0 stars")
		return 0

# 🟢 ADD THIS NEW FUNCTION:
func _check_win_condition_met(player_id: int, condition: String) -> bool:
	"""Checks if a specific win condition was met by a player"""
	
	var p1_score = scoreboard_manager.player1_score
	var p2_score = scoreboard_manager.player2_score
	var p1_landmarks = scoreboard_manager.player1_landmarks
	var p2_landmarks = scoreboard_manager.player2_landmarks
	
	print("    -> Checking: " + condition)
	print("    -> P1 Score: " + str(p1_score) + ", P2 Score: " + str(p2_score))	
	
	match condition:
		"Most Points":
			if player_id == 0:
				return p1_score > p2_score
			else:
				return p2_score > p1_score
				
		"Most Landmarks", "most_landmarks":
			if player_id == 0:
				return p1_landmarks > p2_landmarks
			else:
				return p2_landmarks > p1_landmarks
				
		"Negative Points", "minus_4_points", "win_condition_minus_4_points_3_stars":
			# Player wins if they have -4 or less points
			if player_id == 0:
				return p1_score <= -4
			else:
				return p2_score <= -4
			
		"most_cards", "Most Cards", "win_condition_most_cards_2_stars":
			# Player wins if they have more cards in hand than opponent
			var p1_hand = scoreboard_manager.player1_hand_size
			var p2_hand = scoreboard_manager.player2_hand_size
			
			print("    -> Player 1 has " + str(p1_hand) + " cards, Player 2 has " + str(p2_hand) + " cards")
			
			if player_id == 0:
				return p1_hand > p2_hand
			else:
				return p2_hand > p1_hand
			
		"Deck Empty", "win_condition_deck_runs_out_2_stars":
			# Player wins if the deck is empty
			var deck_empty = deck.is_empty()
			print("    -> Deck empty check: ", deck_empty)
			
			return deck_empty
			
		_:
			print("    -> Unknown win condition: " + condition)
			return false

func _handle_ai_turn():
	"""Handles the AI player's turn"""
	if current_player != 1:  # Only run for Player 2 (AI)

		return
	
	print("=== AI PLAYER 2 TURN ===")
	
	if current_phase == GamePhase.DRAW:
		print("AI is making draw decision...")
		await get_tree().create_timer(AI_DELAY).timeout
		
		# Random choice: top or bottom card
		if randf() > 0.5:
			print("AI chose TOP CARD")
			player_chose_top_card()
		else:
			print("AI chose BOTTOM CARD")
			player_chose_bottom_card()


func _ai_play_hand_card():
	"""AI logic for playing a card from hand"""
	print("AI is choosing a card to play...")
	await get_tree().create_timer(AI_DELAY).timeout
	
	# Simple AI: play a random card from hand
	# Get Player 2's hand size
	var hand_size = hand.get_hand_size_for_player(1)  # Player 2 is AI
	if hand_size > 0:
		var random_index = randi() % hand_size
		print("AI plays card at index: " + str(random_index))
		
		# Get the card from Player 2's hand
		var card = hand.get_card_at_for_player(random_index, 1)
		
		play_hand_card(random_index)
		
		if not _is_win_condition_card(card):
			# AI randomly chooses target for normal cards
			await get_tree().create_timer(AI_DELAY * 0.5).timeout
			if randf() > 0.5:
				print("AI targets self")
				process_hand_card_effects_on_self()
			else:
				print("AI targets opponent")
				process_hand_card_effects_on_opponent()	
				
func _show_target_buttons():
	"""Shows the target selection buttons"""
	target_self_button.visible = true
	target_opponent_button.visible = true


func _hide_target_buttons():
	"""Hides the target selection buttons"""
	target_self_button.visible = false
	target_opponent_button.visible = false


func _print_game_state():
	"""Prints the current game state for debugging"""
	print("Turn " + str(turn_count + 1) + " - Player " + str(current_player + 1) + " - Phase: " + str(GamePhase.keys()[current_phase]))


# ============================================
#            SIGNAL CALLBACKS
# ============================================

func _on_target_self_pressed():
	"""Called when Target Self button is pressed"""
	print("Target Self button clicked!")
	process_hand_card_effects_on_self()


func _on_target_opponent_pressed():
	"""Called when Target Opponent button is pressed"""
	print("Target Opponent button clicked!")
	process_hand_card_effects_on_opponent()
	
	
	# ============================================
#                GAME FLOW DIAGRAM
# ============================================
#
# GAME START:
# └─► start_new_game()
#     ├─ Reset game state (player=0, phase=DRAW, turn=0)
#     ├─ deck.start_new_game()
#     ├─ deck.deal_starting_hand()
#     └─► _handle_ai_turn() [only if current_player==1]
#
# TURN FLOW (repeats until game ends):
#
# [PHASE: DRAW]
# ├─► Human Player (Player 0):
# │   └─ Waits for button click...
# │       ├─► player_chose_top_card() ──┐
# │       └─► player_chose_bottom_card() ┴─► _process_card_choice(bool)
# │                                           ├─ Draw chosen card to hand
# │                                           ├─ Get forced card
# │                                           ├─► _process_forced_card(card)
# │                                           │   ├─ Add to active area
# │                                           │   ├─ Check: _is_win_condition_card()?
# │                                           │   │   ├─ YES ─► _process_win_condition_card()
# │                                           │   │   │         └─► _process_single_card_effects(card, current_player)
# │                                           │   │   └─ NO ──► _process_single_card_effects(card, current_player)
# │                                           │   └─ Clear active area & discard
# │                                           └─► _advance_to_hand_play()
# │                                               └─ Set phase = HAND_PLAY
# │
# └─► AI Player (Player 1):
#     └─► _handle_ai_turn()
#         ├─ Wait AI_DELAY
#         ├─ Random choice
#         └─► player_chose_top_card() OR player_chose_bottom_card()
#             └─ (follows same flow as human above)
#
# [PHASE: HAND_PLAY]
# ├─► Human Player:
# │   └─ Clicks on card in hand...
# │       └─► play_hand_card(index)
# │           ├─ Remove card from hand
# │           ├─ Add to active area
# │           ├─ Check: _is_win_condition_card()?
# │           │   ├─ YES ─► _process_win_condition_card()
# │           │   │         ├─► _process_single_card_effects(card, current_player)
# │           │   │         └─► _cleanup_turn() [skips target selection]
# │           │   └─ NO ──► _show_target_buttons()
# │           │             └─ Waits for button click...
# │           │                 ├─► _on_target_self_pressed()
# │           │                 │   └─► process_hand_card_effects_on_self()
# │           │                 │       ├─► _process_active_card_effects(current_player)
# │           │                 │       │   └─► _process_single_card_effects(each card, target)
# │           │                 │       └─► _cleanup_turn()
# │           │                 └─► _on_target_opponent_pressed()
# │           │                     └─► process_hand_card_effects_on_opponent()
# │           │                         ├─► _process_active_card_effects(opponent)
# │           │                         │   └─► _process_single_card_effects(each card, target)
# │           │                         └─► _cleanup_turn()
# │
# └─► AI Player:
#     └─► _ai_play_hand_card()
#         ├─ Wait AI_DELAY
#         ├─ Pick random card
#         ├─► play_hand_card(index)
#         ├─ Check: _is_win_condition_card()?
#         │   ├─ YES ─ (auto processes, no target needed)
#         │   └─ NO ──► Random target choice
#         │             ├─► process_hand_card_effects_on_self()
#         │             └─► process_hand_card_effects_on_opponent()
#         └─ (follows same flow as human)
#
# [PHASE: CLEANUP]
# └─► _cleanup_turn()
#     ├─ Hide target buttons
#     ├─ Move active cards → discard
#     ├─ Switch current_player (0↔1)
#     ├─ Increment turn_count
#     ├─ Update scoreboard
#     ├─► _check_game_end()?
#     │   ├─ YES ─► _end_game()
#     │   │         ├─► _calculate_player_stars(0)
#     │   │         │   └─► _check_win_condition_met()
#     │   │         ├─► _calculate_player_stars(1)
#     │   │         │   └─► _check_win_condition_met()
#     │   │         └─ Declare winner
#     │   └─ NO ──┐
#     │           │
#     ├─ Set phase = DRAW
#     └─► _handle_ai_turn() [starts next turn]
#         └─ (loops back to TURN FLOW)
#
# ============================================
#                HELPER FUNCTIONS
# ============================================
# These can be called at various points:
#
# _is_win_condition_card(card) -> bool
#   └─ Checks if card has "win_condition" effect
#
# _process_single_card_effects(card, target_player)
#   ├─ Apply point value (if any)
#   └─ Apply each effect via effect_library
#
# _show_target_buttons() / _hide_target_buttons()
#   └─ UI visibility control
#
# _print_game_state()
#   └─ Debug output
#
# ============================================
