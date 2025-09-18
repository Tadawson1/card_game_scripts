# File: res://effect_library.gd
extends Node

# ============================================
#                  CONSTANTS
# ============================================

# Effect categories for organization
enum EffectCategory {
	CARD_MANIPULATION,  # Draw, discard, steal cards
	LANDMARKS,          # Add/remove landmarks
	POINTS,            # Score manipulation
	WIN_CONDITIONS,    # Special win conditions
	SPECIAL           # Other unique effects
}

# ============================================
#                  VARIABLES
# ============================================

# Node References
@onready var deck = get_node("../deck")
@onready var hand = get_node("../hand")
@onready var discard = get_node("../discard")
@onready var scoreboard = get_node("../scoreboard_manager")
@onready var active_area = get_node("../active_card_area")
@onready var game2_node = get_node("../Node2D")


# Track effect statistics (for debugging)
var effects_applied: int = 0
var effects_failed: int = 0


# ============================================
#              GODOT FUNCTIONS
# ============================================

func _ready():
	print("Effect Library initialized")
	_validate_nodes()



# ============================================
#            PUBLIC FUNCTIONS
#        (Called by gamemgr and cards)
# ============================================

func apply_effect(effect_name: String, target_player: int, source_player: int, params: Dictionary = {}) -> bool:
	"""
	Applies a named effect to a target player
	Returns true if effect was successfully applied
	"""
	
	# Validate inputs
	if not _validate_effect_inputs(effect_name, target_player, source_player):
		return false
	
	print("Applying effect: " + effect_name + " to Player " + str(target_player + 1))
	
	var initial_state = _capture_initial_state(target_player)	
	
	# Apply the effect based on its name
	var success: bool = false
	
	match effect_name:
		# ===== CARD MANIPULATION EFFECTS =====
		"draw_card":
			success = _effect_draw_cards(target_player, params.get("amount", 1))
		
		"draw_2_cards":
			success = _effect_draw_cards(target_player, 2)
		
		"discard_card":
			success = _effect_discard_cards(target_player, params.get("amount", 1))
		
		"opponent_discards":
			var opponent = (source_player + 1) % 2
			success = _effect_discard_cards(opponent, params.get("amount", 1))
			
		"opponent_draws":
			var opponent = (source_player + 1) % 2
			success = _effect_draw_cards(opponent, params.get("amount", 1))		
		
		"all_players_draw":
			success = _effect_all_players_draw(params.get("amount", 1))
		
		
		# ===== LANDMARK EFFECTS =====
		"add_landmark":
			success = _effect_add_landmarks(target_player, params.get("amount", 1))
		
		"add_landmark_2":
			success = _effect_add_landmarks(target_player, 2)
		
		"remove_landmark":
			success = _effect_remove_landmarks(target_player, params.get("amount", 1))
		
		# ===== POINT EFFECTS =====
		"add_points":
			success = _effect_add_points(target_player, params.get("amount", 1))
		
		"remove_points":
			success = _effect_remove_points(target_player, params.get("amount", 1))
		
		"points_for_most_landmarks":
			success = _effect_points_for_most_landmarks(target_player)
		
		"points_if_least_landmarks":
			success = _effect_points_if_least_landmarks(target_player)
			
		"draw_if_opponent_most_landmarks":
			success = _effect_conditional_draw_opponent_landmarks(target_player, true)
		
		"draw_if_most_landmarks_2":
			success = _effect_conditional_draw_landmarks_multiple(target_player, true, 2)			
			
		
		# ===== WIN CONDITION EFFECTS =====
		"win_condition_most_landmarks_2_stars":
			success = _effect_activate_win_condition(target_player, "most_landmarks", 2)
		
		"win_condition_minus_4_points_3_stars":
			success = _effect_activate_win_condition(target_player, "negative_points", 3)
		
		"win_condition_most_cards_2_stars":
			success = _effect_activate_win_condition(target_player, "most_cards", 2)
		
		"win_condition_deck_runs_out_2_stars":
			success = _effect_activate_win_condition(target_player, "deck_empty", 2)
		
		# ===== SPECIAL EFFECTS =====
		"look_rearrange_top_3":
			success = _effect_look_rearrange_top(target_player, 3)
		
		"draw_if_most_landmarks":
			success = _effect_conditional_draw_landmarks(target_player, true)
		
		"draw_if_fewest_landmarks":
			success = _effect_conditional_draw_landmarks(target_player, false)
		
		"draw_per_landmark":
			success = _effect_draw_per_landmark(target_player)
		
		
		# ===== DEFAULT =====
		_:
			print("  -> Effect not implemented yet: " + effect_name)
			success = false
			
	_track_and_show_changes(target_player, effect_name, success, initial_state)
	
	# Track statistics
	if success:
		effects_applied += 1
	else:
		effects_failed += 1
	
	return success


func get_effect_description(effect_name: String) -> String:
	"""Returns a human-readable description of an effect"""
	match effect_name:
		"draw_card": return "Draw 1 card"
		"draw_2_cards": return "Draw 2 cards"
		"discard_card": return "Discard 1 card"
		"opponent_discards": return "Opponent discards 1 card"
		"add_landmark": return "Gain 1 landmark"
		"add_landmark_2": return "Gain 2 landmarks"
		"add_points": return "Gain points"
		"remove_points": return "Lose points"
		"draw_if_most_landmarks": return "Draw 1 card if you have most landmarks"
		"draw_if_fewest_landmarks": return "Draw 1 card if you have fewest landmarks" 
		"draw_per_landmark": return "Draw 1 card per landmark you have"
		"draw_if_most_landmarks_2": return "Draw 2 cards if you have most landmarks"
		"draw_if_opponent_most_landmarks": return "Draw 1 card if opponent has most landmarks"
		#win-con effects
		"win_condition_most_landmarks_2_stars": return "Win Condition: Most Landmarks (2★)"
		"win_condition_minus_4_points_3_stars": return "Win Condition: Negative Points (3★)"
		"win_condition_most_cards_2_stars": return "Win Condition: Most Cards (2★)"
		"win_condition_deck_runs_out_2_stars": return "Win Condition: Deck Empty (2★)"
		_: return "Unknown effect"

# ============================================
#         PRIVATE EFFECT FUNCTIONS
#            (Internal use only)
# ============================================

func _show_effect_message(message: String, color: Color = Color.CYAN):
	"""Helper function to display effect messages"""
	if game2_node and game2_node.has_method("show_effect_message"):
		game2_node.show_effect_message(message, color)
		
func _capture_initial_state(target_player: int) -> Dictionary:
	"""Captures the current state before applying an effect"""
	var state = {
		"score": 0,
		"landmarks": 0,
		"hand_size": 0
	}
	
	if scoreboard:
		state.score = scoreboard.player1_score if target_player == 0 else scoreboard.player2_score
		state.landmarks = scoreboard.get_player_stat(target_player, "landmarks")
	
	if hand:
		state.hand_size = hand.get_hand_size_for_player(target_player)
	
	return state		
	
func _track_and_show_changes(target_player: int, effect_name: String, success: bool, initial_state: Dictionary) -> void:
	"""Compares initial state to current state and shows appropriate messages"""
	if not success:
		return
	
	var player_name = "Player " + str(target_player + 1)
	
	# Check score changes
	if scoreboard:
		var current_score = scoreboard.player1_score if target_player == 0 else scoreboard.player2_score
		var score_change = current_score - initial_state.score
		
		if score_change != 0:
			if score_change > 0:
				_show_effect_message(player_name + ": Points +" + str(score_change), Color.GREEN)
			else:
				_show_effect_message(player_name + ": Points " + str(score_change), Color.RED)
		
		# Check landmark changes
		var current_landmarks = scoreboard.get_player_stat(target_player, "landmarks")
		var landmark_change = current_landmarks - initial_state.landmarks
		
		if landmark_change != 0:
			if landmark_change > 0:
				_show_effect_message(player_name + ": Landmarks +" + str(landmark_change), Color.CYAN)
			else:
				_show_effect_message(player_name + ": Landmarks " + str(landmark_change), Color.ORANGE)
	
	# Check hand size changes
	if hand:
		var current_hand_size = hand.get_hand_size_for_player(target_player)
		var hand_change = current_hand_size - initial_state.hand_size
		
		if hand_change > 0:
			_show_effect_message(player_name + ": Drew " + str(hand_change) + " card(s)", Color.YELLOW)
		elif hand_change < 0:
			_show_effect_message(player_name + ": Discarded " + str(abs(hand_change)) + " card(s)", Color.PURPLE)
	
	# Special messages for win conditions
	if effect_name.begins_with("win_condition"):
		var readable_name = get_effect_description(effect_name)
		_show_effect_message(player_name + ": " + readable_name + " activated!", Color.GOLD)	

# ===== CARD MANIPULATION EFFECTS =====

func _effect_draw_cards(player_id: int, amount: int) -> bool:
	"""Makes a player draw cards"""
	print("  -> Player " + str(player_id + 1) + " draws " + str(amount) + " card(s)")
	
	if not deck or not hand:
		print("  -> ERROR: Deck or hand not found")
		return false
	
	var cards_drawn = 0
	for i in range(amount):
		if deck.get_remaining_count() > 0:
			var drawn_card = deck.draw_top_card()
			# Use player-specific add
			hand.add_card_for_player(drawn_card, player_id)
			print("  -> Drew: " + drawn_card.name)
			cards_drawn += 1
			
			# Update hand size in scoreboard for the correct player
			var gamemgr = get_node("../gamemgr")
			if gamemgr and gamemgr.scoreboard_manager:
				gamemgr.scoreboard_manager.update_player_hand_size(
					player_id, 
					hand.get_hand_size_for_player(player_id)
				)
		else:
			print("  -> Deck is empty, cannot draw more cards")
			break
	
	return cards_drawn > 0

func _effect_discard_cards(player_id: int, amount: int) -> bool:
	"""Makes a player discard cards (for now, discards random cards)"""
	print("  -> Player " + str(player_id + 1) + " discards " + str(amount) + " card(s)")
	
	if not hand or not discard:
		print("  -> ERROR: Hand or discard not found")
		return false
	
	var cards_discarded = 0
	for i in range(amount):
		var hand_size = hand.get_hand_size_for_player(player_id)
		if hand_size > 0:
			# For now, discard a random card (could add player choice later)
			var random_index = randi() % hand_size
			var discarded_card = hand.remove_card_for_player(random_index, player_id)
			if discarded_card:
				discard.add_card(discarded_card)
				print("  -> Discarded: " + discarded_card.name)
				cards_discarded += 1
				
				# Update hand size in scoreboard
				var gamemgr = get_node("../gamemgr")
				if gamemgr and gamemgr.scoreboard_manager:
					gamemgr.scoreboard_manager.update_player_hand_size(
						player_id,
						hand.get_hand_size_for_player(player_id)
					)
		else:
			print("  -> Player has no cards to discard")
			break
	
	return cards_discarded > 0


func _effect_all_players_draw(amount: int) -> bool:
	"""All players draw cards"""
	var success = true
	for player_id in range(2):
		if not _effect_draw_cards(player_id, amount):
			success = false
	return success


# ===== LANDMARK EFFECTS =====

func _effect_add_landmarks(player_id: int, amount: int) -> bool:
	"""Adds landmarks to a player"""
	print("  -> Player " + str(player_id + 1) + " gains " + str(amount) + " landmark(s)")
	
	# For now, track in scoreboard
	if scoreboard:
		for i in range(amount):
			scoreboard.set_player_stat(player_id, "landmarks", 
				scoreboard.get_player_stat(player_id, "landmarks") + 1)
				
		return true
	
	return false


func _effect_remove_landmarks(player_id: int, amount: int) -> bool:
	"""Removes landmarks from a player"""
	print("  -> Player " + str(player_id + 1) + " loses " + str(amount) + " landmark(s)")
	
	if scoreboard:
		var current = scoreboard.get_player_stat(player_id, "landmarks")
		var new_value = max(0, current - amount)  # Can't go below 0
		scoreboard.set_player_stat(player_id, "landmarks", new_value)
		print("  -> Landmarks: " + str(current) + " -> " + str(new_value))
		return true
	
	return false


# ===== POINT EFFECTS =====

func _effect_add_points(player_id: int, amount: int) -> bool:
	"""Adds or subtracts points from a player's score"""
	if amount > 0:
		print("  -> Player " + str(player_id + 1) + " gains " + str(amount) + " point(s)")
	elif amount < 0:
		print("  -> Player " + str(player_id + 1) + " loses " + str(abs(amount)) + " point(s)")
	else:
		print("  -> No point change (amount is 0)")
		return true
	
	if scoreboard:
		var current_score = scoreboard.player1_score if player_id == 0 else scoreboard.player2_score
		var new_score = current_score + amount  # This works for both positive and negative
		scoreboard.update_player_score(player_id, new_score)
		
		return true
	
	return false


func _effect_remove_points(player_id: int, amount: int) -> bool:
	"""Removes points from a player's score"""
	print("  -> Player " + str(player_id + 1) + " loses " + str(amount) + " point(s)")
	
	if scoreboard:
		var current_score = scoreboard.player1_score if player_id == 0 else scoreboard.player2_score
		scoreboard.update_player_score(player_id, max(0, current_score - amount))
		return true
	
	return false


func _effect_points_for_most_landmarks(player_id: int) -> bool:
	"""Gives points if player has most landmarks"""
	if not scoreboard:
		print("  -> ERROR: Scoreboard not found")
		return false
	
	var p1_landmarks = scoreboard.player1_landmarks
	var p2_landmarks = scoreboard.player2_landmarks
	
	print("  -> Checking landmarks: P1=" + str(p1_landmarks) + " P2=" + str(p2_landmarks))
	
	var has_most = false
	if player_id == 0:
		has_most = p1_landmarks > p2_landmarks
	else:
		has_most = p2_landmarks > p1_landmarks
	
	if has_most:
		print("  -> Player " + str(player_id + 1) + " has most landmarks! Gaining 3 points")
		return _effect_add_points(player_id, 3)  # Adjust points as needed
	else:
		print("  -> Player " + str(player_id + 1) + " does not have most landmarks, no points")
		return true  # Still succeeds, just doesn't give points


func _effect_points_if_least_landmarks(player_id: int) -> bool:
	"""Gives points if player has least landmarks"""
	if not scoreboard:
		print("  -> ERROR: Scoreboard not found")
		return false
	
	var p1_landmarks = scoreboard.player1_landmarks
	var p2_landmarks = scoreboard.player2_landmarks
	
	print("  -> Checking landmarks: P1=" + str(p1_landmarks) + " P2=" + str(p2_landmarks))
	
	var has_least = false
	if player_id == 0:
		has_least = p1_landmarks < p2_landmarks
	else:
		has_least = p2_landmarks < p1_landmarks
	
	if has_least:
		print("  -> Player " + str(player_id + 1) + " has least landmarks! Gaining 2 points")
		return _effect_add_points(player_id, 2)  # Adjust points as needed
	else:
		print("  -> Player " + str(player_id + 1) + " does not have least landmarks, no points")
		return true  # Still succeeds, just doesn't give points
		
func _effect_conditional_draw_opponent_landmarks(player_id: int, need_most: bool) -> bool:
	"""Draw cards based on whether OPPONENT has most landmarks"""
	
	var p1_landmarks = scoreboard.player1_landmarks
	var p2_landmarks = scoreboard.player2_landmarks
	var opponent_id = (player_id + 1) % 2
	
	var should_draw = false
	if need_most:  # Player draws if OPPONENT has MOST landmarks
		if opponent_id == 0:
			should_draw = p1_landmarks > p2_landmarks
		else:
			should_draw = p2_landmarks > p1_landmarks
		print("  -> Checking if opponent has most landmarks: P1=" + str(p1_landmarks) + " P2=" + str(p2_landmarks) + " -> Draw: " + str(should_draw))
	
	if should_draw:
		return _effect_draw_cards(player_id, 1)
	else:
		print("  -> Opponent doesn't have most landmarks, no cards drawn")
		return true  # Still succeeds, just doesn't drawdraw
		
func _effect_conditional_draw_landmarks_multiple(player_id: int, need_most: bool, card_count: int) -> bool:
	"""Draw multiple cards based on landmark count"""
	
	var p1_landmarks = scoreboard.player1_landmarks
	var p2_landmarks = scoreboard.player2_landmarks
	
	var should_draw = false
	if need_most:  # Player needs MOST landmarks to draw
		if player_id == 0:
			should_draw = p1_landmarks > p2_landmarks
		else:
			should_draw = p2_landmarks > p1_landmarks
		print("  -> Checking most landmarks for " + str(card_count) + " cards: P1=" + str(p1_landmarks) + " P2=" + str(p2_landmarks) + " -> Draw: " + str(should_draw))
	else:  # Player needs FEWEST landmarks to draw
		if player_id == 0:
			should_draw = p1_landmarks < p2_landmarks
		else:
			should_draw = p2_landmarks < p1_landmarks
		print("  -> Checking fewest landmarks for " + str(card_count) + " cards: P1=" + str(p1_landmarks) + " P2=" + str(p2_landmarks) + " -> Draw: " + str(should_draw))
	
	if should_draw:
		return _effect_draw_cards(player_id, card_count)
	else:
		print("  -> Condition not met, no cards drawn")
		return true  # Still succeeds, just doesn't draw		


# ===== WIN CONDITION EFFECTS =====

func _effect_activate_win_condition(player_id: int, condition: String, stars: int) -> bool:
	"""Activates a win condition for a player"""
	print("  -> Player " + str(player_id + 1) + " activates win condition: " + condition + " (" + str(stars) + " stars)")
	
	if scoreboard:
		if player_id == 0:
			scoreboard.update_player1_win_condition(condition, stars)
			return true
		elif player_id == 1:
			scoreboard.update_player2_win_condition(condition, stars)
			return true
	
	print("  -> ERROR: Scoreboard not found or invalid player_id")
	return false


# ===== SPECIAL EFFECTS =====

func _effect_look_rearrange_top(player_id: int, card_count: int) -> bool:
	"""Look at top cards and rearrange them"""
	print("  -> Player " + str(player_id + 1) + " looks at top " + str(card_count) + " cards")
	
	if not deck:
		print("  -> ERROR: Deck not found")
		return false
	
	# Get the top cards
	var top_cards = []
	for i in range(card_count):
		if not deck.is_empty():
			var card = deck.draw_top_card()
			if card:
				top_cards.append(card)
				print("    Card " + str(i + 1) + ": " + card.name)
	
	if top_cards.is_empty():
		print("  -> No cards to rearrange")
		return false
	
	# For now, just randomize their order (later could add UI for player choice)
	top_cards.shuffle()
	print("  -> Cards shuffled and returned to deck")
	
	# Put them back on top of deck in reverse order (last one goes on top)
	for i in range(top_cards.size() - 1, -1, -1):
		# We need to add a function to put cards back on top
		deck.add_card_to_top(top_cards[i])
	
	return true


func _effect_conditional_draw_landmarks(player_id: int, need_most: bool) -> bool:
	"""Draw cards based on landmark count"""
	
	var p1_landmarks = scoreboard.player1_landmarks
	var p2_landmarks = scoreboard.player2_landmarks
	
	var should_draw = false
	if need_most:  # Player needs MOST landmarks to draw
		if player_id == 0:
			should_draw = p1_landmarks > p2_landmarks
		else:
			should_draw = p2_landmarks > p1_landmarks
		print("  -> Checking most landmarks: P1=" + str(p1_landmarks) + " P2=" + str(p2_landmarks) + " -> Draw: " + str(should_draw))
	else:  # Player needs FEWEST landmarks to draw
		if player_id == 0:
			should_draw = p1_landmarks < p2_landmarks
		else:
			should_draw = p2_landmarks < p1_landmarks
		print("  -> Checking fewest landmarks: P1=" + str(p1_landmarks) + " P2=" + str(p2_landmarks) + " -> Draw: " + str(should_draw))
	
	if should_draw:
		return _effect_draw_cards(player_id, 1)
	else:
		print("  -> Condition not met, no cards drawn")
		return true  # Still succeeds, just doesn't draw


func _effect_draw_per_landmark(player_id: int) -> bool:
	"""Draw cards equal to landmark count"""
	if scoreboard:
		var landmark_count = scoreboard.get_player_stat(player_id, "landmarks")
		print("  -> Player " + str(player_id + 1) + " has " + str(landmark_count) + " landmarks")
		if landmark_count > 0:
			print("  -> Drawing " + str(landmark_count) + " cards")
			return _effect_draw_cards(player_id, landmark_count)
		else:
			print("  -> No landmarks, no cards drawn")
			return true  # Still succeeds, just doesn't draw
	return false


# ============================================
#          HELPER FUNCTIONS
# ============================================

func _validate_nodes() -> bool:
	"""Validates that all required nodes exist"""
	var all_valid = true
	
	if not deck:
		print("WARNING: Deck node not found in Effect Library")
		all_valid = false
	if not hand:
		print("WARNING: Hand node not found in Effect Library")
		all_valid = false
	if not scoreboard:
		print("WARNING: Scoreboard node not found in Effect Library")
		all_valid = false
	
	return all_valid


func _validate_effect_inputs(effect_name: String, target_player: int, source_player: int) -> bool:
	"""Validates effect parameters"""
	if target_player < 0 or target_player > 1:
		print("ERROR: Invalid target player ID: " + str(target_player))
		effects_failed += 1
		return false
	
	if source_player < 0 or source_player > 1:
		print("ERROR: Invalid source player ID: " + str(source_player))
		effects_failed += 1
		return false
	
	if effect_name.is_empty():
		print("ERROR: Empty effect name")
		effects_failed += 1
		return false
	
	return true


func get_statistics() -> Dictionary:
	"""Returns effect usage statistics"""
	return {
		"effects_applied": effects_applied,
		"effects_failed": effects_failed,
		"success_rate": float(effects_applied) / float(max(1, effects_applied + effects_failed))
	}
