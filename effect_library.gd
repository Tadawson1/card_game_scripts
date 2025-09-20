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

func apply_effect(effect_name: String, target_player: int, activating_player: int, params: Dictionary = {}) -> Dictionary:
	"""
	Applies a named effect to a target player
	target_player: who receives the effect
	activating_player: who played the card (for logging)
	Returns dictionary with success status and details
	"""
	
	# Validate inputs
	if not _validate_effect_inputs(effect_name, target_player, activating_player):
		return {"success": false, "requested": 0, "actual": 0, "effect": effect_name}
		
	var actual_target = target_player  # Default to target_player
	var who_value = params.get("who", "target")  # Default to "target" if not specified
	
	if who_value == "other":
		# Switch to the other player
		actual_target = (target_player + 1) % 2
		print("Effect targets 'other' - switching from Player " + str(target_player + 1) + " to Player " + str(actual_target + 1))
	elif who_value == "all":
		# Special case - will be handled per effect
		print("Effect targets 'all' players")
	else:  # "target" or unspecified
		actual_target = target_player
	
	
	print("Player " + str(activating_player + 1) + " uses " + effect_name + " on Player " + str(target_player + 1))
	
	var initial_state = {}
	var initial_state_p1 = {}
	var initial_state_p2 = {}
	
	if who_value == "all":
		initial_state_p1 = _capture_initial_state(0)
		initial_state_p2 = _capture_initial_state(1)
	else:
		initial_state = _capture_initial_state(actual_target)	
	
	# Apply the effect based on its name
	var result: Dictionary = {"success": false, "requested": 0, "actual": 0, "effect": effect_name}
	

	match effect_name:
		# ===== CARD MANIPULATION EFFECTS =====
		"draw":
			var amount = params.get("amount", 1)
			# Handle "all" special case
			if who_value == "all":
				var result_p1 = _effect_draw_cards(0, amount)
				var result_p2 = _effect_draw_cards(1, amount)
				result = {"success": result_p1.success and result_p2.success, 
						 "requested": amount * 2, 
						 "actual": result_p1.actual + result_p2.actual, 
						 "effect": effect_name}
			else:
				result = _effect_draw_cards(actual_target, amount)

		"discard":
			var amount = params.get("amount", 1)
			# "all" case for discard (if needed in future)
			if who_value == "all":
				var result_p1 = _effect_discard_cards(0, amount)
				var result_p2 = _effect_discard_cards(1, amount)
				result = {"success": result_p1.success and result_p2.success,
						 "requested": amount * 2,
						 "actual": result_p1.actual + result_p2.actual,
						 "effect": effect_name}
			else:
				result = _effect_discard_cards(actual_target, amount)
		
		# ===== LANDMARK EFFECTS =====
		"add_landmark":
			result = _effect_add_landmarks(actual_target, params.get("amount", 1))
		
		"remove_landmark":
			result = _effect_remove_landmarks(actual_target, params.get("amount", 1))
		
		# ===== POINT EFFECTS =====
		"add_points":
			result = _effect_add_points(actual_target, params.get("amount", 1))
		
		"remove_points":
			result = _effect_remove_points(actual_target, params.get("amount", 1))
		
		"points_conditional":
			var amount = params.get("amount", 1)
			var condition = params.get("condition", "most_landmarks")
			result = _effect_conditional_points_landmarks(actual_target, condition, amount)

		"draw_conditional":
			var amount = params.get("amount", 1)
			var condition = params.get("condition", "most_landmarks")
			result = _effect_conditional_draw_landmarks(actual_target, condition, amount)
		
		
		
		# ======= win conditions======= #
		"win_condition_minus_4_points_3_stars":
			result = _effect_activate_win_condition(activating_player, "negative_points", 3)
		
		"win_condition_most_cards_2_stars":
			result = _effect_activate_win_condition(activating_player, "most_cards", 2)
		
		"win_condition_deck_runs_out_2_stars":
			result = _effect_activate_win_condition(activating_player, "deck_empty", 2)
		
		# ===== DEFAULT =====
		_:
			print("  -> Effect not implemented yet: " + effect_name)
			result = {"success": false, "requested": 0, "actual": 0, "effect": effect_name}
	
	if who_value == "all":
		# Track changes for both players
		_track_and_show_changes(0, effect_name, result["success"], initial_state_p1)
		_track_and_show_changes(1, effect_name, result["success"], initial_state_p2)
	else:
		# Track changes for the actual target
		_track_and_show_changes(actual_target, effect_name, result["success"], initial_state)
	
	# Track statistics
	if result["success"]:
		effects_applied += 1
	else:
		effects_failed += 1
	
	return result


func get_effect_description(effect_name: String) -> String:
	"""Returns a human-readable description of an effect"""
	match effect_name:
		"draw_card": return "Draw 1 card"
		"discard_card": return "Discard 1 card"
		"add_landmark": return "Gain 1 landmark"
		"add_points": return "Gain points"
		"remove_points": return "Lose points"
		"draw_if_most_landmarks": return "Draw 1 card if you have most landmarks"
		"draw_if_fewest_landmarks": return "Draw 1 card if you have fewest landmarks" 
		"draw_per_landmark": return "Draw 1 card per landmark you have"
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

func _effect_draw_cards(player_id: int, amount: int) -> Dictionary:
	"""Makes a player draw cards"""
	print("  -> Player " + str(player_id + 1) + " draws " + str(amount) + " card(s)")
	
	if not deck or not hand:
		print("  -> ERROR: Deck or hand not found")
		return {"success": false, "requested": amount, "actual": 0, "effect": "draw_cards"}
	
	var cards_drawn = 0
	for i in range(amount):
		if deck.get_remaining_count() > 0:
			var drawn_card = deck.draw_top_card()
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
	
	print("  -> Drew " + str(cards_drawn) + " of " + str(amount) + " requested cards")
	return {"success": cards_drawn > 0, "requested": amount, "actual": cards_drawn, "effect": "draw_cards"}

func _effect_discard_cards(player_id: int, amount: int) -> Dictionary:
	"""Makes a player discard cards (for now, discards random cards)"""
	print("  -> Player " + str(player_id + 1) + " discards " + str(amount) + " card(s)")
	
	if not hand or not discard:
		print("  -> ERROR: Hand or discard not found")
		return {"success": false, "requested": amount, "actual": 0, "effect": "discard_cards"}
	
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
	
	print("  -> Discarded " + str(cards_discarded) + " of " + str(amount) + " requested cards")
	return {"success": cards_discarded > 0, "requested": amount, "actual": cards_discarded, "effect": "discard_cards"}


func _effect_conditional_draw_landmarks(player_id: int, condition: String, amount: int) -> Dictionary:
	"""Draw cards based on landmark conditions"""
	if not scoreboard:
		print("  -> ERROR: Scoreboard not found")
		return {"success": false, "requested": amount, "actual": 0, "effect": "conditional_draw"}
	
	var p1_landmarks = scoreboard.player1_landmarks
	var p2_landmarks = scoreboard.player2_landmarks
	var should_draw = false
	var draw_amount = amount
	
	match condition:
		"most_landmarks":
			# Check if target player has most landmarks
			if player_id == 0:
				should_draw = p1_landmarks > p2_landmarks
			else:
				should_draw = p2_landmarks > p1_landmarks
			print("  -> Target has most landmarks? " + str(should_draw))
			
		"fewest_landmarks":
			# Check if target player has fewest landmarks
			if player_id == 0:
				should_draw = p1_landmarks < p2_landmarks
			else:
				should_draw = p2_landmarks < p1_landmarks
			print("  -> Target has fewest landmarks? " + str(should_draw))
			
		"opponent_most_landmarks":
			# Check if target's opponent has most landmarks
			var opponent_id = (player_id + 1) % 2
			if opponent_id == 0:
				should_draw = p1_landmarks > p2_landmarks
			else:
				should_draw = p2_landmarks > p1_landmarks
			print("  -> Target's opponent has most landmarks? " + str(should_draw))
			
		"per_landmark":
			# Draw cards equal to target's landmark count
			var landmark_count = p1_landmarks if player_id == 0 else p2_landmarks
			draw_amount = landmark_count
			should_draw = landmark_count > 0
			print("  -> Target has " + str(landmark_count) + " landmarks, drawing that many cards")
			
		_:
			print("  -> Unknown condition: " + condition)
			return {"success": false, "requested": 0, "actual": 0, "effect": "conditional_draw"}
	
	if should_draw:
		return _effect_draw_cards(player_id, draw_amount)
	else:
		print("  -> Condition not met, no cards drawn")
		return {"success": true, "requested": 0, "actual": 0, "effect": "conditional_draw"}


# ===== LANDMARK EFFECTS =====

func _effect_add_landmarks(player_id: int, amount: int) -> Dictionary:
	"""Adds landmarks to a player"""
	print("  -> Player " + str(player_id + 1) + " gains " + str(amount) + " landmark(s)")
	
	if scoreboard:
		for i in range(amount):
			scoreboard.set_player_stat(player_id, "landmarks", 
				scoreboard.get_player_stat(player_id, "landmarks") + 1)
		
		return {"success": true, "requested": amount, "actual": amount, "effect": "add_landmarks"}
	
	return {"success": false, "requested": amount, "actual": 0, "effect": "add_landmarks"}


func _effect_remove_landmarks(player_id: int, amount: int) -> Dictionary:
	"""Removes landmarks from a player"""
	print("  -> Player " + str(player_id + 1) + " loses " + str(amount) + " landmark(s)")
	
	if scoreboard:
		var current = scoreboard.get_player_stat(player_id, "landmarks")
		var new_value = max(0, current - amount)  # Can't go below 0
		var actual_removed = current - new_value
		scoreboard.set_player_stat(player_id, "landmarks", new_value)
		print("  -> Landmarks: " + str(current) + " -> " + str(new_value))
		return {"success": true, "requested": amount, "actual": actual_removed, "effect": "remove_landmarks"}
	
	return {"success": false, "requested": amount, "actual": 0, "effect": "remove_landmarks"}


# ===== POINT EFFECTS =====

func _effect_add_points(player_id: int, amount: int) -> Dictionary:
	"""Adds or subtracts points from a player's score"""
	if amount > 0:
		print("  -> Player " + str(player_id + 1) + " gains " + str(amount) + " point(s)")
	elif amount < 0:
		print("  -> Player " + str(player_id + 1) + " loses " + str(abs(amount)) + " point(s)")
	else:
		print("  -> No point change (amount is 0)")
		return {"success": true, "requested": 0, "actual": 0, "effect": "add_points"}
	
	if scoreboard:
		var current_score = scoreboard.player1_score if player_id == 0 else scoreboard.player2_score
		var new_score = current_score + amount  # This works for both positive and negative
		scoreboard.update_player_score(player_id, new_score)
		
		return {"success": true, "requested": amount, "actual": amount, "effect": "add_points"}
	
	return {"success": false, "requested": amount, "actual": 0, "effect": "add_points"}


func _effect_remove_points(player_id: int, amount: int) -> Dictionary:
	"""Removes points from a player's score"""
	print("  -> Player " + str(player_id + 1) + " loses " + str(amount) + " point(s)")
	
	if scoreboard:
		var current_score = scoreboard.player1_score if player_id == 0 else scoreboard.player2_score
		var new_score = current_score - amount  # Allow going negative
		scoreboard.update_player_score(player_id, new_score)
		return {"success": true, "requested": amount, "actual": amount, "effect": "remove_points"}
	
	return {"success": false, "requested": amount, "actual": 0, "effect": "remove_points"}



# ===== WIN CONDITION EFFECTS =====

func _effect_activate_win_condition(player_id: int, condition: String, stars: int) -> Dictionary:
	"""Activates a win condition for a player"""
	var gamemgr = get_node("../gamemgr")
	var actual_player = gamemgr.current_player if gamemgr else player_id
	print("  -> Player " + str(actual_player + 1) + " activates win condition: " + condition + " (" + str(stars) + " stars)")
	
	if scoreboard:
		if actual_player == 0:
			scoreboard.update_player1_win_condition(condition, stars)
			return {"success": true, "requested": 1, "actual": 1, "effect": "activate_win_condition"}
		elif actual_player == 1:
			scoreboard.update_player2_win_condition(condition, stars)
			return {"success": true, "requested": 1, "actual": 1, "effect": "activate_win_condition"}
	
	print("  -> ERROR: Scoreboard not found or invalid player_id")
	return {"success": false, "requested": 1, "actual": 0, "effect": "activate_win_condition"}



func _effect_conditional_points_landmarks(player_id: int, condition: String, amount: int) -> Dictionary:
	"""Give points based on landmark conditions"""
	if not scoreboard:
		print("  -> ERROR: Scoreboard not found")
		return {"success": false, "requested": amount, "actual": 0, "effect": "conditional_points"}
	
	var p1_landmarks = scoreboard.player1_landmarks
	var p2_landmarks = scoreboard.player2_landmarks
	var should_give_points = false
	
	match condition:
		"most_landmarks":
			# Check if target player has most landmarks
			if player_id == 0:
				should_give_points = p1_landmarks > p2_landmarks
			else:
				should_give_points = p2_landmarks > p1_landmarks
			print("  -> Target has most landmarks? " + str(should_give_points))
			
		"least_landmarks":
			# Check if target player has least landmarks
			if player_id == 0:
				should_give_points = p1_landmarks < p2_landmarks
			else:
				should_give_points = p2_landmarks < p1_landmarks
			print("  -> Target has least landmarks? " + str(should_give_points))
			
		_:
			print("  -> Unknown condition: " + condition)
			return {"success": false, "requested": 0, "actual": 0, "effect": "conditional_points"}
	
	if should_give_points:
		print("  -> Condition met! Target gains " + str(amount) + " points")
		return _effect_add_points(player_id, amount)
	else:
		print("  -> Condition not met, no points awarded")
		return {"success": true, "requested": 0, "actual": 0, "effect": "conditional_points"}

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


func _validate_effect_inputs(effect_name: String, target_player: int, activating_player: int) -> bool:
	"""Validates effect parameters"""
	if target_player < 0 or target_player > 1:
		print("ERROR: Invalid target player ID: " + str(target_player))
		effects_failed += 1
		return false
	
	if activating_player < 0 or activating_player > 1:
		print("ERROR: Invalid activating player ID: " + str(activating_player))
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
