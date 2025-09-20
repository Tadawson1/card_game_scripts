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
	RETURN_CARD, 
	CLEANUP 
}

const MAX_TURNS: int = 4
const STARTING_HAND_SIZE: int = 3
const AI_THINK_TIME: float = 1.5  # Base thinking time
const AI_QUICK_DECISION: float = 0.5  # For follow-up decisions

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
var forced_card = null
var selected_draw_index: int = -1
var pending_hand_card = null  # Card selected from hand but not yet played

# UI Elements (created dynamically)
var target_self_button: Button
var target_opponent_button: Button
var game_over_label: Label
var game_over_panel: Panel
var selected_return_index: int = -1



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
	
	if not hand:
		print("ERROR: Hand node not found!")
		return	
	
	# Setup deck and deal starting hands
	deck.start_new_game()

	for i in range(STARTING_HAND_SIZE):
		# Player 1's starting hand
		if not deck.is_empty():
			var card1 = deck.draw_top_card()
			if card1:
				hand.add_card_for_player(card1, 0, false) #suppress refresh
		
		# Player 2's starting hand
		if not deck.is_empty():
			var card2 = deck.draw_top_card()
			if card2:
				hand.add_card_for_player(card2, 1)  #ai has no display
				
	hand._refresh_hand_display()			
	
	scoreboard_manager.update_player_hand_size(0, hand.get_hand_size_for_player(0))
	scoreboard_manager.update_player_hand_size(1, hand.get_hand_size_for_player(1))	

	
	print("=== GAME MANAGER: Game Ready ===")
	_print_game_state()
	
	# Update scoreboard
	scoreboard_manager.update_current_player(current_player)
	scoreboard_manager.update_turn(turn_count + 1)
	
		# Show draw buttons for Player 1's first turn
	if game2_node and game2_node.has_method("update_button_visibility"):
		game2_node.update_button_visibility(current_phase, current_player)
	
	# Start first turn
	_handle_ai_turn()
	

func player_chose_top_card():
	"""Handles when player chooses to draw/return the top card"""
	if current_phase == GamePhase.DRAW:
		print("GameManager: Player chose to FORCE PLAY TOP CARD")
		_process_card_choice(true)
	elif current_phase == GamePhase.RETURN_CARD:
		if game2_node and game2_node.selected_return_index == -1:
			print("Select a card to return first.")
			return
		print("GameManager: Player returns SELECTED card to TOP")
		_process_return_card(true)  # uses game2's selected_return_index
	else:
		print("ERROR: Invalid phase for this action!")


func player_chose_bottom_card():
	"""Handles when player chooses to draw/return the bottom (second) card"""
	if current_phase == GamePhase.DRAW:
		print("GameManager: Player chose to FORCE PLAY BOTTOM CARD")
		_process_card_choice(false)
	elif current_phase == GamePhase.RETURN_CARD:
		if game2_node and game2_node.selected_return_index == -1:
			print("Select a card to return first.")
			return
		print("GameManager: Player returns SELECTED card as SECOND")
		_process_return_card(false)  # uses game2's selected_return_index
	else:
		print("ERROR: Invalid phase for this action!")

func select_return_card(index: int):
	if current_phase != GamePhase.RETURN_CARD:
		print("Ignoring selection; not in RETURN_CARD phase")
		return

	# Update game2's selected index
	if game2_node:
		# Toggle: tap the same card again to clear selection
		if game2_node.selected_return_index == index:
			game2_node.selected_return_index = -1
			print("Selection cleared.")
			if card_display and card_display.has_method("clear_hand_selection"):
				card_display.clear_hand_selection()
			# Update button visibility (will hide buttons since no selection)
			game2_node.update_button_visibility(current_phase, current_player)
			return

		game2_node.selected_return_index = index
		print("Selected card for return at index: " + str(index))
		
		# Visual highlight
		if card_display and card_display.has_method("highlight_hand_selection"):
			card_display.highlight_hand_selection(index)

		# Update button visibility (will show return buttons now that card is selected)
		game2_node.update_button_visibility(current_phase, current_player)


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
	
	# Re-layout after removal using intended size
	if card_display:
		card_display.refresh_hand_layout_with_count(hand.get_hand_size_for_player(current_player))	
	
		# Store the card as pending instead of adding to active area immediately
	pending_hand_card = hand_card
	
	if card_display:
		card_display.load_forced_card_image(hand_card.name)

	_print_game_state()
	
	# Check if card requires target selection
	if hand_card.get("requires_target", true) == false:
		print("Card auto-targets self (no target selection needed)")
		_hide_target_buttons()
		
		current_phase = GamePhase.EFFECT_RESOLUTION
		_print_game_state()
		
		process_hand_card_effects(current_player)
	else:
		print("Waiting for target selection...")
	# Show target selection buttons for normal cards
		_show_target_buttons()
	# Stay in HAND_PLAY phase - will move to EFFECT_RESOLUTION when target is chosen


func process_hand_card_effects(target_player: int):
	"""Processes the played hand card's effects targeting the specified player"""
	var target_name = "SELF" if target_player == current_player else "OPPONENT"
	print("=== PROCESSING HAND CARD EFFECTS ON " + target_name + " ===")
	
	# Move pending card to active area now that target is chosen
	if pending_hand_card:
		active_card_area.add_card(pending_hand_card)
	else:
		print("ERROR: No pending card to process!")
		return
	
	# NOW change to effect resolution phase
	current_phase = GamePhase.EFFECT_RESOLUTION
	_print_game_state()
	
	_process_active_card_effects(target_player)
	
	# Clear active area and move cards to discard (like forced cards do)
	var cards_to_discard = active_card_area.clear_all_cards()
	for card in cards_to_discard:
		discard.add_card(card)
	print("Moved hand card to discard")
	
	# Clear the pending card
	pending_hand_card = null

	# Move to RETURN_CARD phase
	current_phase = GamePhase.RETURN_CARD
	_print_game_state()
	
		# Update button visibility (won't show return buttons until card selected)
	if game2_node and game2_node.has_method("update_button_visibility"):
		game2_node.update_button_visibility(current_phase, current_player)

	# Hide target buttons
	_hide_target_buttons()

	# Hide Draw Top/Bottom buttons during return selection
	if game2_node and game2_node.has_method("hide_card_choice_buttons"):
		game2_node.hide_card_choice_buttons()

	# Check if player has cards to return
	var hand_size: int = hand.get_hand_size_for_player(current_player)
	if hand_size > 0:
		if current_player == 0:
			print("Player must now SELECT a card to return, then choose Top/Second.")
		else:
			_ai_return_card()
	else:
		print("No cards in hand to return, skipping return phase")
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
	
	#checks if deck out or not
	if deck.get_remaining_count() < 2:
		print("Deck doesn't have enough cards to continue - ending game!")
		_end_game()
		return
			
	# Draw both cards
	var top_card = deck.draw_top_card()
	var bottom_card = deck.draw_top_card()  # Second card drawn is "bottom"
	
	var drawn_card
	var forced_card
	
	if chose_top:
		forced_card = top_card      # Chose top, force play top
		drawn_card = bottom_card   # Draw bottom to hand
	else:
		forced_card = bottom_card    #Choose bottom, force play bottom 
		drawn_card = top_card      # Draw top to hand
	
	print("Chose to FORCE PLAY: " + forced_card.name)
	print("Drawn to hand: " + drawn_card.name)
	
	if game2_node and game2_node.has_method("show_card_movement"):
		game2_node.show_card_movement(drawn_card.name, forced_card.name)	
		
	current_phase = GamePhase.FORCED_PLAY
	_print_game_state()		
	
		# Hide force card buttons immediately after choice
	if game2_node and game2_node.has_method("update_button_visibility"):
		game2_node.update_button_visibility(current_phase, current_player)
	
	
	_process_forced_card(forced_card)
	
	# Add chosen card to current player's hand
	hand.add_card_for_player(drawn_card, current_player)
	
	# Update hand size for the current player
	scoreboard_manager.update_player_hand_size(current_player, hand.get_hand_size_for_player(current_player))
	
	# Re-layout based on intended size (not what’s rendered yet)
	if card_display:
		card_display.refresh_hand_layout_with_count(hand.get_hand_size_for_player(current_player))
		
	_advance_to_hand_play()

func _process_forced_card(card):
	"""Processes the forced card's effects and discards it"""
	print("=== PROCESSING FORCED CARD EFFECTS ===")
	active_card_area.add_card(card)
	
	if card_display:
		card_display.load_forced_card_image(card.name)	
	
	print("Processing effects for forced card: " + card.name)
	# Forced cards always affect current player
	_process_single_card_effects(card, current_player)	
	
	# Move forced card to discard
	var cards_to_discard = active_card_area.clear_all_cards()
	for discard_card in cards_to_discard:
		discard.add_card(discard_card)
	
	print("=== FORCED CARD EFFECTS COMPLETE ===")

func _process_return_card(return_to_top: bool):
	"""Handles returning a card from hand to deck"""
	if current_phase != GamePhase.RETURN_CARD:
		print("ERROR: Not in return card phase!")
		return
	
	# For now, return a random card (later we can add UI for selection)
	var hand_size: int = hand.get_hand_size_for_player(current_player)
	if hand_size == 0:
		print("No cards to return!")
		_cleanup_turn()
		return
	
	# Use game2's selected index if available, otherwise random
	var return_index = -1
	if current_player == 0 and game2_node and game2_node.selected_return_index >= 0:
		return_index = game2_node.selected_return_index
	else:
		# AI or no selection - use random
		return_index = randi() % hand_size
	
	var returned_card = hand.remove_card_for_player(return_index, current_player)
	
	# Clear selection in game2
	if game2_node:
		game2_node.selected_return_index = -1
	
	# Clear visual selection too
	if card_display and card_display.has_method("clear_hand_selection"):
		card_display.clear_hand_selection()
	
	if returned_card == null:
		print("ERROR: Failed to remove card for return!")
		_cleanup_turn()
		return
	
	# Add card back to deck
	if return_to_top:
		print("Returning " + returned_card.name + " to TOP of deck")
		deck.add_card_to_top(returned_card)
	else:
		print("Returning " + returned_card.name + " as SECOND card in deck")
		deck.add_card_to_position(returned_card, 1)
	
	# Update hand size display
	scoreboard_manager.update_player_hand_size(current_player, hand.get_hand_size_for_player(current_player))
	
	# Now proceed to cleanup
	_cleanup_turn()

func _ai_return_card():
	"""AI logic for returning a card to deck"""
	print("AI is deciding where to return a card...")
	await get_tree().create_timer(AI_QUICK_DECISION).timeout
	
	# Simple AI: randomly choose top or second position
	if randf() > 0.5:
		print("AI returns card to TOP")
		_process_return_card(true)
	else:
		print("AI returns card as SECOND")
		_process_return_card(false)


func _advance_to_hand_play():
	"""Advances the game to the hand play phase"""
	print("=== ADVANCING TO HAND PLAY PHASE ===")
	current_phase = GamePhase.HAND_PLAY
	_print_game_state()
	print("Player must now choose a card from hand to play")
	
	if current_player == 1:
		_ai_play_hand_card()	
		
func _process_single_card_effects(card, target_player: int):
	"""Processes all effects of a single card"""
	# Process point value if it has one
	if card.has("points") and card.points != 0:
		print("Card has " + str(card.points) + " points")
		effect_library.apply_effect("add_points", target_player, current_player, {"amount": card.points})
	
	if card.has("effects"):
		print("Card effects: ", card.effects)
		for effect in card.effects:	
			# Check if card has parameters like how many to draw etc.
			var params = {}
			if card.has("effect_params") and card.effect_params.has(effect):
				params = card.effect_params[effect].duplicate()  # Duplicate to avoid modifying original
				
			# Special handling for "all" target
			if params.get("target", "") == "all":
				print("  Effect " + effect + " targets all players")
				params.erase("target")  # Remove target from params since we handle it here
				# Apply to both players
				effect_library.apply_effect(effect, 0, current_player, params)
				effect_library.apply_effect(effect, 1, current_player, params)
			else:
				# Normal single-target effect
				if params.has("target"):
					params.erase("target")  # Remove old target system from params
				print("  Effect " + effect + " has params: ", params)
				effect_library.apply_effect(effect, target_player, current_player, params)

func _process_active_card_effects(target_player: int):
	"""Processes the active card's effects targeting the specified player"""
	# Get the single card that was just played (should be only one)
	var active_cards = active_card_area.active_cards
	if active_cards.is_empty():
		print("WARNING: No cards in active area to process")
		return
	
	if active_cards.size() > 1:
		print("WARNING: Multiple cards in active area, processing first one only")
	
	var card = active_cards[0]  # Process the first (and should be only) card
	print("Processing effects for: " + card.name + " (targeting Player " + str(target_player + 1) + ")")
	_process_single_card_effects(card, target_player)
	print("Card effects complete")


func _cleanup_turn():
	"""Cleans up the current turn and prepares for the next"""
	print("=== CLEANUP PHASE ===")
	current_phase = GamePhase.CLEANUP
	_print_game_state()
	
	# Hide target buttons
	_hide_target_buttons()
	
	# Active area should already be empty (cleared after processing)
	# Just verify and warn if not
	if not active_card_area.is_empty():
		print("WARNING: Active area not empty during cleanup!")
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
	
	if game2_node and game2_node.has_method("update_button_visibility"):
		game2_node.update_button_visibility(current_phase, current_player)
	
	_handle_ai_turn()
	
func _check_game_end() -> bool:
	"""Checks if the game should end"""
	if turn_count >= (MAX_TURNS * 2):
		print("Maximum turns reached!")
		return true
	
	# Add other end conditions here (deck empty, special win conditions, etc.)
	
	return false
	
	
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
	if current_player != 0:  # AI turn
		# Hide buttons during AI turn
		if game2_node and game2_node.has_method("update_button_visibility"):
			game2_node.update_button_visibility(current_phase, current_player)
	
	if current_player != 1:  # Only run for Player 2 (AI)
		return
	
	
	print("=== AI PLAYER 2 TURN ===")
	
	if current_phase == GamePhase.DRAW:
		print("AI is making draw decision...")
		await get_tree().create_timer(AI_THINK_TIME).timeout
		
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
	await get_tree().create_timer(AI_QUICK_DECISION).timeout
	
	# Simple AI: play a random card from hand
	# Get Player 2's hand size
	var hand_size = hand.get_hand_size_for_player(1)  # Player 2 is AI
	if hand_size > 0:
		var random_index = randi() % hand_size
		print("AI plays card at index: " + str(random_index))
		
		# Get the card from Player 2's hand to check metadata
		var card = hand.get_card_at_for_player(random_index, 1)

		play_hand_card(random_index)

		# Check if card requires target selection
		if card.get("requires_target", true) == false:
			print("AI's card auto-targets self")
			await get_tree().create_timer(AI_QUICK_DECISION).timeout
			process_hand_card_effects(current_player)
		else:
			# AI randomly chooses target for cards that require it
			await get_tree().create_timer(AI_QUICK_DECISION).timeout
			if randf() > 0.5:
				print("AI targets self")
				process_hand_card_effects(current_player)
			else:
				print("AI targets opponent")
				var opponent = (current_player + 1) % 2
				process_hand_card_effects(opponent)
				
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
	process_hand_card_effects(current_player)


func _on_target_opponent_pressed():
	"""Called when Target Opponent button is pressed"""
	print("Target Opponent button clicked!")
	var opponent = (current_player + 1) % 2
	process_hand_card_effects(opponent)
	
