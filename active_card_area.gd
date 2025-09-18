# File: res://active_card_area.gd
extends Node

# ============================================
#                  CONSTANTS
# ============================================

const MAX_ACTIVE_CARDS: int = 10  # Safety limit to prevent infinite loops
const DEBUG_MODE: bool = false

# ============================================
#                  VARIABLES
# ============================================

# Cards currently in the active area
var active_cards: Array = []

# Track who played each card (for effects that care about source)
var card_sources: Dictionary = {}  # card -> player_id


# ============================================
#              GODOT FUNCTIONS
# ============================================

func _ready():
	print("Active Card Area initialized")


# ============================================
#            PUBLIC FUNCTIONS
#        (Called by other scripts)
# ============================================

func add_card(card, source_player: int = -1) -> bool:
	"""
	Adds a card to the active area
	source_player: ID of player who played it (-1 if unknown/forced)
	"""
	if card == null:
		print("WARNING: Attempted to add null card to active area")
		return false
	
	if active_cards.size() >= MAX_ACTIVE_CARDS:
		print("WARNING: Active area full (" + str(MAX_ACTIVE_CARDS) + " cards)")
		return false
	
	active_cards.append(card)
	
	# Track who played it
	if source_player >= 0:
		card_sources[card] = source_player
	
	print("Added to active area: " + card.name + " (" + str(card.points) + " points)")
	if source_player >= 0:
		print("  -> Played by Player " + str(source_player + 1))
	print("Active area now has " + str(active_cards.size()) + " cards")
	
	return true


func clear_all_cards() -> Array:
	"""Removes and returns all cards from the active area"""
	var cards_to_return = active_cards.duplicate()
	active_cards.clear()
	card_sources.clear()
	
	print("Cleared " + str(cards_to_return.size()) + " cards from active area")
	return cards_to_return


func remove_card(card) -> bool:
	"""Removes a specific card from the active area"""
	if card in active_cards:
		active_cards.erase(card)
		if card in card_sources:
			card_sources.erase(card)
		print("Removed " + card.name + " from active area")
		return true
	
	print("WARNING: Card " + card.name + " not found in active area")
	return false


func remove_card_at(index: int):
	"""Removes and returns the card at the specified index"""
	if index < 0 or index >= active_cards.size():
		print("ERROR: Invalid index " + str(index) + " for active area")
		return null
	
	var card = active_cards[index]
	active_cards.remove_at(index)
	if card in card_sources:
		card_sources.erase(card)
	
	print("Removed " + card.name + " from active area (index " + str(index) + ")")
	return card


func get_cards() -> Array:
	"""Returns a copy of all cards in the active area"""
	return active_cards.duplicate()


func get_card_at(index: int):
	"""Returns the card at the specified index without removing it"""
	if index < 0 or index >= active_cards.size():
		return null
	return active_cards[index]


func get_card_count() -> int:
	"""Returns the number of cards in the active area"""
	return active_cards.size()


func is_empty() -> bool:
	"""Returns true if the active area has no cards"""
	return active_cards.is_empty()


func has_card(card_name: String) -> bool:
	"""Checks if a card with the given name is in the active area"""
	for card in active_cards:
		if card.name == card_name:
			return true
	return false


func get_cards_by_player(player_id: int) -> Array:
	"""Returns all cards played by a specific player"""
	var player_cards = []
	for card in active_cards:
		if card in card_sources and card_sources[card] == player_id:
			player_cards.append(card)
	return player_cards


func get_card_source(card) -> int:
	"""Returns the player ID who played this card, or -1 if unknown"""
	return card_sources.get(card, -1)


func get_total_points() -> int:
	"""Calculates the total points of all cards in the active area"""
	var total = 0
	for card in active_cards:
		if card.has("points"):
			total += card.points
	return total


func get_cards_with_effect(effect_name: String) -> Array:
	"""Returns all cards that have a specific effect"""
	var matching_cards = []
	for card in active_cards:
		if card.has("effects"):
			for effect in card.effects:
				if effect == effect_name:
					matching_cards.append(card)
					break
	return matching_cards


# ============================================
#            PRIVATE FUNCTIONS
#            (Internal use only)
# ============================================

func _validate_card(card) -> bool:
	"""Validates that a card object is valid"""
	if card == null:
		return false
	if not card.has("name"):
		print("WARNING: Card missing 'name' property")
		return false
	return true


# ============================================
#            DEBUG FUNCTIONS
#            (For testing only)
# ============================================

func _print_active_area_status():
	"""Prints the current status of the active area for debugging"""
	print("=== ACTIVE CARD AREA STATUS ===")
	print("Total cards: " + str(active_cards.size()))
	
	if active_cards.is_empty():
		print("(Empty)")
	else:
		for i in range(active_cards.size()):
			var card = active_cards[i]
			var source = get_card_source(card)
			var source_text = " (Player " + str(source + 1) + ")" if source >= 0 else ""
			print("  " + str(i+1) + ": " + card.name + source_text)
		
		print("Total points in area: " + str(get_total_points()))
	
	print("================================")


func get_statistics() -> Dictionary:
	"""Returns statistics about the active area"""
	var stats = {
		"card_count": active_cards.size(),
		"is_empty": active_cards.is_empty(),
		"total_points": get_total_points(),
		"cards_by_player": {0: 0, 1: 0, -1: 0}  # -1 for unknown/forced
	}
	
	# Count cards by player
	for card in active_cards:
		var source = get_card_source(card)
		if source in stats.cards_by_player:
			stats.cards_by_player[source] += 1
	
	return stats
