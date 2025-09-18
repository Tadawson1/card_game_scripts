# File: res://discard.gd
extends Node

# ============================================
#                  VARIABLES
# ============================================

# Cards in the discard pile (newest on top/end of array)
var discard_cards = []


# ============================================
#              GODOT FUNCTIONS
# ============================================

func _ready():
	print("Discard pile initialized")


# ============================================
#            PUBLIC FUNCTIONS
#        (Called by other scripts)
# ============================================

func add_card(card) -> bool:
	"""Adds a single card to the discard pile"""
	if card == null:
		print("WARNING: Attempted to discard null card")
		return false
	
	discard_cards.append(card)
	print("Added to discard: " + card.name + " (" + str(card.points) + " points)")
	print("Discard pile now has " + str(discard_cards.size()) + " cards")
	return true


func add_multiple_cards(cards: Array) -> int:
	"""Adds multiple cards to the discard pile, returns count added"""
	var added_count = 0
	for card in cards:
		if add_card(card):
			added_count += 1
	return added_count


func get_top_card():
	"""Returns the top card without removing it (peek)"""
	if discard_cards.is_empty():
		return null
	return discard_cards[-1]  # Last element is top of pile


func take_top_card():
	"""Removes and returns the top card"""
	if discard_cards.is_empty():
		print("Discard pile is empty, cannot take card")
		return null
	
	var card = discard_cards.pop_back()
	print("Took from discard: " + card.name)
	print("Discard pile now has " + str(discard_cards.size()) + " cards")
	return card


func take_all_cards() -> Array:
	"""Removes and returns all cards (used for reshuffling)"""
	var all_cards = discard_cards.duplicate()
	discard_cards.clear()
	print("Took all " + str(all_cards.size()) + " cards from discard pile")
	return all_cards


func get_card_count() -> int:
	"""Returns the number of cards in the discard pile"""
	return discard_cards.size()


func is_empty() -> bool:
	"""Returns true if the discard pile is empty"""
	return discard_cards.is_empty()


func has_card(card_name: String) -> bool:
	"""Checks if a card with the given name is in the discard"""
	for card in discard_cards:
		if card.name == card_name:
			return true
	return false


func get_cards_by_name(card_name: String) -> Array:
	"""Returns all cards with the given name"""
	var matching_cards = []
	for card in discard_cards:
		if card.name == card_name:
			matching_cards.append(card)
	return matching_cards


func get_all_card_names() -> Array:
	"""Returns a list of all card names in the discard"""
	var names = []
	for card in discard_cards:
		names.append(card.name)
	return names


func clear_discard():
	"""Removes all cards from the discard pile"""
	var count = discard_cards.size()
	discard_cards.clear()
	print("Cleared discard pile (" + str(count) + " cards removed)")


func get_last_discarded(count: int = 1) -> Array:
	"""Returns the last X cards discarded without removing them"""
	if count <= 0:
		return []
	
	var start_index = max(0, discard_cards.size() - count)
	return discard_cards.slice(start_index)


# ============================================
#            DEBUG FUNCTIONS
#            (For testing only)
# ============================================

func print_discard_contents():
	"""Prints all cards in the discard pile for debugging"""
	print("=== DISCARD PILE CONTENTS ===")
	if discard_cards.is_empty():
		print("(Empty)")
	else:
		print("Total cards: " + str(discard_cards.size()))
		print("Top 5 cards (most recent first):")
		var show_count = min(5, discard_cards.size())
		for i in range(show_count):
			var index = discard_cards.size() - 1 - i
			var card = discard_cards[index]
			print("  " + str(i + 1) + ". " + card.name + " (" + str(card.points) + " points)")
		
		if discard_cards.size() > 5:
			print("  ... and " + str(discard_cards.size() - 5) + " more cards")
	print("=========================")


func get_statistics() -> Dictionary:
	"""Returns statistics about the discard pile"""
	var stats = {
		"total_cards": discard_cards.size(),
		"is_empty": discard_cards.is_empty(),
		"unique_cards": {},
		"total_points": 0
	}
	
	# Count unique cards and total points
	for card in discard_cards:
		if not stats.unique_cards.has(card.name):
			stats.unique_cards[card.name] = 0
		stats.unique_cards[card.name] += 1
		
		if card.has("points"):
			stats.total_points += card.points
	
	return stats
