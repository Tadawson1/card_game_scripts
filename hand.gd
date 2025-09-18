# File: res://hand.gd
extends Node

# ============================================
#                  VARIABLES
# ============================================

# Cards currently in hand
var hand_cards = []
var player2_hand_cards = []
var refresh_timer_active: bool = false



# Node references
@onready var card_display = get_node("../card_display")


# ============================================
#              GODOT FUNCTIONS
# ============================================

func _ready():
	print("Hand manager initialized")


# ============================================
#            PUBLIC FUNCTIONS
#        (Called by other scripts)
# ============================================

func add_card_for_player(card, player_id: int, skip_refresh: bool = false):
	"""Adds a card to the specified player's hand"""
	if player_id == 0:
		hand_cards.append(card)
		print("Added to Player 1's hand: " + card.name + " (" + str(card.points) + " points)")
		if not skip_refresh:  # ADD THIS CHECK
			_refresh_hand_display()  # Only refresh display if not skipped
	elif player_id == 1:
		player2_hand_cards.append(card)
		print("Added to Player 2's hand: " + card.name + " (" + str(card.points) + " points)")
		# No display refresh for AI player
	else:
		print("ERROR: Invalid player_id: " + str(player_id))


func remove_card(card_index: int):
	"""Removes a card from the hand at the specified index and returns it"""
	# Validate index
	if card_index < 0 or card_index >= hand_cards.size():
		print("ERROR: Invalid card index " + str(card_index) + " for hand of size " + str(hand_cards.size()))
		return null
	
	# Remove and store the card
	var removed_card = hand_cards[card_index]
	hand_cards.remove_at(card_index)
	print("Removed from hand: " + removed_card.name + " (" + str(removed_card.points) + " points)")
	
	# Refresh display after removal
	_refresh_hand_display()
	
	return removed_card


func get_hand_size() -> int:
	"""Returns the current number of cards in hand"""
	return hand_cards.size()
	
func get_hand_size_for_player(player_id: int) -> int:
	"""Returns the hand size for the specified player"""
	if player_id == 0:
		return hand_cards.size()
	elif player_id == 1:
		return player2_hand_cards.size()
	else:
		print("ERROR: Invalid player_id: " + str(player_id))
		return 0

func get_card_at_for_player(index: int, player_id: int):
	"""Returns a card from the specified player's hand without removing it"""
	if player_id == 0:
		if index < 0 or index >= hand_cards.size():
			return null
		return hand_cards[index]
	elif player_id == 1:
		if index < 0 or index >= player2_hand_cards.size():
			return null
		return player2_hand_cards[index]
	else:
		print("ERROR: Invalid player_id: " + str(player_id))
		return null	
		
func remove_card_for_player(card_index: int, player_id: int):
	"""Removes a card from the specified player's hand and returns it"""
	if player_id == 0:
		if card_index < 0 or card_index >= hand_cards.size():
			print("ERROR: Invalid card index " + str(card_index))
			return null
		var removed_card = hand_cards[card_index]
		hand_cards.remove_at(card_index)
		print("Removed from Player 1's hand: " + removed_card.name)
		_refresh_hand_display()
		return removed_card
	elif player_id == 1:
		if card_index < 0 or card_index >= player2_hand_cards.size():
			print("ERROR: Invalid card index " + str(card_index))
			return null
		var removed_card = player2_hand_cards[card_index]
		player2_hand_cards.remove_at(card_index)
		print("Removed from Player 2's hand: " + removed_card.name)
		return removed_card
	else:
		print("ERROR: Invalid player_id: " + str(player_id))
		return null

func get_card_at(index: int):
	"""Returns the card at the specified index without removing it"""
	if index < 0 or index >= hand_cards.size():
		return null
	return hand_cards[index]


func clear_hand():
	"""Removes all cards from the hand"""
	hand_cards.clear()
	print("Hand cleared")


# ============================================
#            PRIVATE FUNCTIONS
#            (Internal use only)
# ============================================

func _refresh_hand_display():
	"""Updates the visual display of cards in hand"""
	print("Refreshing hand display - showing all " + str(hand_cards.size()) + " cards")
	
	# Check if card_display is available
	if card_display == null:
		print("WARNING: card_display not found, cannot refresh display")
		return
	
	# Clear all existing card displays first
	card_display.clear_all_hand_cards()
	
	# Display all cards in hand
	for i in range(hand_cards.size()):
		var card = hand_cards[i]
		print("Showing hand card " + str(i) + ": ", card.name)
		card_display.load_card_image(card.name, i)
		
	if hand_cards.size() > 0 and not refresh_timer_active:
		refresh_timer_active = true
		print("DEBUG: Setting timer for layout refresh (hand size: " + str(hand_cards.size()) + ")")
		
		await get_tree().create_timer(0.5).timeout
		
		print("DEBUG: Timer expired, calling refresh_hand_layout")
		
		if card_display and card_display.has_method("refresh_hand_layout"):
			card_display.refresh_hand_layout()
		
		refresh_timer_active = false		
