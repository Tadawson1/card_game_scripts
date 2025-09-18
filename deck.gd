# File: res://deck.gd
extends Node

# ============================================
#                  CONSTANTS
# ============================================

const SHUFFLE_ITERATIONS: int = 3  # How many times to shuffle for better randomization
const DEBUG_MODE: bool = false  # Set to true to enable debug prints

# ============================================
#                  VARIABLES
# ============================================

# Node References
@onready var card_library = $"../card_library"
@onready var discard = $"../discard"

# Deck state
var deck_cards = []
var cards_dealt_total: int = 0  # Track total cards dealt this game


# ============================================
#              GODOT FUNCTIONS
# ============================================

func _ready():
	print("Deck manager initialized")


# ============================================
#            PUBLIC FUNCTIONS
#        (Called by other scripts)
# ============================================

func start_new_game():
	"""Initializes the deck for a new game"""
	print("=== STARTING NEW DECK ===")
	cards_dealt_total = 0
	_load_cards()
	_shuffle_deck()
	
	if DEBUG_MODE:
		_print_deck_status()


func draw_top_card():
	"""Draws and returns the top card from the deck"""
	if deck_cards.is_empty():
			print("ERROR: No cards available to draw!")
			return null
	
	var card = deck_cards.pop_front()
	cards_dealt_total += 1
	
	print("Drew card: " + card.name + " (" + str(card.points) + " points)")
	print("Cards remaining in deck: " + str(deck_cards.size()))
	
	return card


func draw_cards(count: int) -> Array:
	"""Draws multiple cards from the top of the deck"""
	var drawn_cards = []
	for i in range(count):
		var card = draw_top_card()
		if card != null:
			drawn_cards.append(card)
		else:
			print("Could only draw " + str(i) + " of " + str(count) + " requested cards")
			break
	return drawn_cards


func deal_starting_hand(hand_node, num_cards: int) -> bool:
	"""Deals cards to a hand at game start"""
	if hand_node == null:
		print("ERROR: Invalid hand node provided")
		return false
	
	print("Dealing " + str(num_cards) + " cards to starting hand...")
	
	for i in range(num_cards):
		var card = draw_top_card()
		if card != null:
			hand_node.add_card(card)
		else:
			print("ERROR: Not enough cards to deal starting hand")
			return false
	
	return true


func get_top_cards(count: int) -> Array:
	"""Returns the top X cards without removing them (for preview)"""
	if count <= 0:
		return []
	
	var available = min(count, deck_cards.size())
	var top_cards = []
	
	for i in range(available):
		top_cards.append(deck_cards[i])
	
	if available < count:
		print("Only " + str(available) + " cards available (requested " + str(count) + ")")
	
	return top_cards


func get_top_two_cards() -> Array:
	"""Returns the top 2 cards for player choice (convenience function)"""
	return get_top_cards(2)

func get_remaining_count() -> int:
	"""Returns the number of cards remaining in the deck"""
	return deck_cards.size()


func is_empty() -> bool:
	"""Returns true if the deck has no cards left"""
	return deck_cards.is_empty()


func has_enough_cards(count: int) -> bool:
	"""Checks if deck has at least 'count' cards"""
	return deck_cards.size() >= count

func add_card_to_top(card):
	"""Adds a card to the top of the deck"""
	if card == null:
		print("WARNING: Attempted to add null card to deck")
		return
	
	deck_cards.push_front(card)  # Add to front (top) of deck
	print("Added " + card.name + " to top of deck")

func add_card_to_bottom(card):
	"""Adds a card to the second position from the top (below the top card)"""
	if card == null:
		print("WARNING: Attempted to add null card to deck bottom")
		return
	
	if deck_cards.is_empty():
		# If deck is empty, just add to top
		deck_cards.push_front(card)
		print("Added " + card.name + " to empty deck")
	elif deck_cards.size() == 1:
		# If only one card, add as second card
		deck_cards.append(card)
		print("Added " + card.name + " as second card in deck")
	else:
		# Insert at position 1 (second from top)
		deck_cards.insert(1, card)
		print("Added " + card.name + " to second position in deck")

func add_cards_to_bottom(cards: Array) -> int:
	"""Adds cards to the bottom of the deck, returns count added"""
	var added = 0
	for card in cards:
		if card != null:
			deck_cards.append(card)
			added += 1
	
	if added > 0:
		print("Added " + str(added) + " cards to bottom of deck")
	
	return added

func add_card_to_position(card, position: int):
	"""Adds a card at a specific position in the deck (0 = top)"""
	if card == null:
		print("WARNING: Attempted to add null card to deck")
		return
	
	if position < 0:
		position = 0
	if position > deck_cards.size():
		position = deck_cards.size()
	
	deck_cards.insert(position, card)
	print("Added " + card.name + " to position " + str(position) + " of deck")


func force_shuffle():
	"""Forces the deck to shuffle (for special effects)"""
	_shuffle_deck()
	print("Deck force-shuffled by effect")


# ============================================
#            PRIVATE FUNCTIONS
#            (Internal use only)
# ============================================

func _load_cards():
	"""Loads all cards from the card library"""
	print("Loading cards from library...")
	
	if card_library == null:
		print("ERROR: Card library not found!")
		return
	
	deck_cards = card_library.cards.duplicate()
	print("Loaded " + str(deck_cards.size()) + " cards into deck")


func _shuffle_deck():
	"""Shuffles the deck (can be called multiple times for better randomization)"""
	if deck_cards.is_empty():
		print("Cannot shuffle empty deck")
		return
	
	# Shuffle multiple times for better randomization
	for iteration in range(SHUFFLE_ITERATIONS):
		deck_cards.shuffle()
	
	print("Deck shuffled (" + str(SHUFFLE_ITERATIONS) + " iterations)")




# ============================================
#            DEBUG FUNCTIONS
#            (For testing only)
# ============================================

func _print_deck_status():
	"""Prints the current deck status for debugging"""
	print("=== DECK STATUS ===")
	print("Cards in deck: " + str(deck_cards.size()))
	print("Cards dealt this game: " + str(cards_dealt_total))
	
	if not deck_cards.is_empty():
		print("Top 5 cards:")
		var show_count = min(5, deck_cards.size())
		for i in range(show_count):
			var card = deck_cards[i]
			print("  " + str(i + 1) + ". " + card.name + " (" + str(card.points) + " points)")
	else:
		print("(Deck is empty)")
	
	print("==================")


func get_statistics() -> Dictionary:
	"""Returns statistics about the deck"""
	return {
		"cards_remaining": deck_cards.size(),
		"cards_dealt_total": cards_dealt_total,
		"is_empty": deck_cards.is_empty(),
		"can_draw_two": deck_cards.size() >= 2
	}
