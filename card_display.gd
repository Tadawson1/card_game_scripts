# File: res://card_display.gd
extends Node

# ============================================
#                  CONSTANTS
# ============================================

# Card display settings
const CARD_WIDTH: int = 433
const CARD_HEIGHT: int = 650
const CARD_SCALE: Vector2 = Vector2(0.6, 0.6)
const CARD_SPACING: int = 300
const CARD_Y_POSITION: int = 550
const CARD_X_START: int = 100

# URL settings
const BASE_URL: String = "https://tadawson1.github.io/Card/"
const FILE_SUFFIX: String = "_v2.jpg"

#hand size dynamic sizing
const MAX_HAND_WIDTH: int = 1800  # Maximum width for all cards
const MIN_CARD_SCALE: float = 0.3  # Minimum scale (30% of original)
const MAX_CARDS_NORMAL_SIZE: int = 4  # Cards stay normal size up to this count

# Debug settings
const DEBUG_MODE: bool = false

# ============================================
#                  VARIABLES
# ============================================

# Node References
@onready var gamemgr = get_node("../gamemgr")
@onready var card_library = get_node("../card_library")

# Track displayed cards for cleanup
var displayed_cards: Array = []
var forced_card_display = null


# Track active HTTP requests for cleanup
var active_requests: Array = []

#track hover state and expand card
var hovered_card = null
const HOVER_SCALE: Vector2 = Vector2(0.9, 0.9)


# ============================================
#              GODOT FUNCTIONS
# ============================================

func _ready():
	print("Card Display Manager initialized")


func _exit_tree():
	"""Clean up when node is removed"""
	_cleanup_http_requests()


# ============================================
#            PUBLIC FUNCTIONS
#        (Called by other scripts)
# ============================================

func load_card_image(card_name: String, position_index: int = 0) -> void:
	"""Loads and displays a card image at the specified position"""
	
	
	# Create HTTP request
	var http_request = _create_http_request()
	
	# Build URL
	var filename = convert_name_to_filename(card_name)
	var url = BASE_URL + filename
	
	if DEBUG_MODE:
		print("Loading card image: ", url)
	
	# Store metadata for callback
	http_request.set_meta("card_name", card_name)
	http_request.set_meta("position_index", position_index)
	
	# Connect completion signal
	http_request.request_completed.connect(
		func(result, response_code, headers, body): 
			_handle_download(card_name, position_index, result, response_code, headers, body)
	)
	
	# Start request
	var error = http_request.request(url)
	if error != OK:
		print("ERROR: Failed to start HTTP request for " + card_name + ": ", error)
		_cleanup_http_request(http_request)

func load_forced_card_image(card_name: String) -> void:
	"""Loads and displays a forced card at 80% size in the active area"""
	# Create HTTP request
	var http_request = _create_http_request()
	
	# Build URL
	var filename = convert_name_to_filename(card_name)
	var url = BASE_URL + filename
	
	if DEBUG_MODE:
		print("Loading forced card image: ", url)
	
	# Store metadata for callback - using special position -1 for forced card
	http_request.set_meta("card_name", card_name)
	http_request.set_meta("position_index", -1)  # -1 indicates forced card
	http_request.set_meta("is_forced", true)
	
	# Connect completion signal
	http_request.request_completed.connect(
		func(result, response_code, headers, body): 
			_handle_forced_card_download(card_name, result, response_code, headers, body)
	)
	
	# Start request
	var error = http_request.request(url)
	if error != OK:
		print("ERROR: Failed to start HTTP request for forced card " + card_name + ": ", error)
		_cleanup_http_request(http_request)


func clear_all_hand_cards():
	"""Removes all displayed card images from the scene"""
	print("Clearing " + str(displayed_cards.size()) + " card displays")
	
	for card_button in displayed_cards:
		if card_button and is_instance_valid(card_button):
			card_button.queue_free()
	
	displayed_cards.clear()
	
func refresh_hand_layout():
	"""Refreshes the layout of all displayed cards based on hand size"""
	var hand_size = displayed_cards.size()
	if hand_size == 0:
		return
	
	print("Refreshing layout for " + str(hand_size) + " cards")	
	
	var new_scale = CARD_SCALE
	var new_spacing = CARD_SPACING
	
	# Only scale down if we have more than MAX_CARDS_NORMAL_SIZE cards
	if hand_size > MAX_CARDS_NORMAL_SIZE:
		# Calculate how much space we need vs what we have
		var total_width_needed = hand_size * CARD_SPACING
		if total_width_needed > MAX_HAND_WIDTH:
			# Scale down to fit
			var scale_factor = float(MAX_HAND_WIDTH) / float(total_width_needed)
			# Don't go below minimum
			scale_factor = max(scale_factor, MIN_CARD_SCALE / CARD_SCALE.x)
			
			new_scale = CARD_SCALE * scale_factor
			new_spacing = CARD_SPACING * scale_factor
			print("  -> Scaling to " + str(new_scale.x) + " with spacing " + str(new_spacing))
			
	for i in range(hand_size):
		var card = displayed_cards[i]
		if card and is_instance_valid(card):
			# Update position
			var new_x = CARD_X_START + (i * new_spacing)
			card.position = Vector2(new_x, CARD_Y_POSITION)
			
			# Update scale
			card.scale = new_scale
			
			# Store the new default scale for hover effects
			card.set_meta("default_scale", new_scale)

func convert_name_to_filename(card_name: String) -> String:
	"""Converts a card name to its corresponding image filename"""
	var converted = card_name.replace(" ", "_")  # Spaces to underscores
	converted = converted.replace("'", "")       # Remove apostrophes
	
	# Handle capitalization: first word stays caps, rest lowercase
	var parts = converted.split("_")
	if parts.size() > 1:
		for i in range(1, parts.size()):
			parts[i] = parts[i].to_lower()
		converted = "_".join(parts)
	
	return converted + FILE_SUFFIX


func refresh_display():
	"""Refreshes all card displays (useful after window resize)"""
	# Could be implemented if needed for responsive design
	pass



# ============================================
#            PRIVATE FUNCTIONS
#            (Internal use only)
# ============================================

func _create_http_request() -> HTTPRequest:
	"""Creates and tracks a new HTTP request node"""
	var http_request = HTTPRequest.new()
	add_child(http_request)
	active_requests.append(http_request)
	return http_request


func _cleanup_http_request(request: HTTPRequest):
	"""Removes and cleans up an HTTP request node"""
	if request in active_requests:
		active_requests.erase(request)
	
	if request and is_instance_valid(request):
		request.queue_free()


func _cleanup_http_requests():
	"""Cleans up all active HTTP requests"""
	for request in active_requests:
		if request and is_instance_valid(request):
			request.queue_free()
	active_requests.clear()
	

func _handle_download(card_name: String, position_index: int, result: int, 
		response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Handles the downloaded card image data"""
	
	# Find and clean up the request
	for request in active_requests:
		if request.get_meta("card_name", "") == card_name:
			_cleanup_http_request(request)
			break
	
	# Check for successful download
	if response_code != 200 or body.size() == 0:
		print("ERROR: Failed to download image for " + card_name + " (code: " + str(response_code) + ")")
		return
	
	# Convert to image
	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		print("ERROR: Failed to parse image for " + card_name)
		return
	
	# Create texture and button
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	_create_card_button(texture, card_name, position_index)
	

func _handle_forced_card_download(card_name: String, result: int, 
		response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Handles the downloaded forced card image data"""
	
	# Find and clean up the request
	for request in active_requests:
		if request.get_meta("card_name", "") == card_name and request.get_meta("is_forced", false):
			_cleanup_http_request(request)
			break
	
	# Check for successful download
	if response_code != 200 or body.size() == 0:
		print("ERROR: Failed to download forced card image for " + card_name)
		return
	
	# Convert to image
	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		print("ERROR: Failed to parse forced card image for " + card_name)
		return
	
	# Create texture and button
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	_create_forced_card_display(texture, card_name)

func _create_forced_card_display(texture: ImageTexture, card_name: String):
	"""Creates the visual display for a forced card at 80% scale"""
	var card_button = TextureButton.new()
	card_button.texture_normal = texture
	
	# Store metadata
	card_button.set_meta("card_name", card_name)
	card_button.set_meta("is_forced", true)
	
	# Set position in active area (center of screen)
	card_button.position = Vector2(1350, 100)
	card_button.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card_button.scale = Vector2(0.8, 0.8)  # 80% size as requested
	
	card_button.mouse_entered.connect(func(): _on_card_hover_start(card_button))
	card_button.mouse_exited.connect(func(): _on_card_hover_end(card_button))
	
	# No click handler for forced cards - they're just display
	card_button.disabled = true
	
	# Add to scene
	var main_scene = get_tree().root.get_child(0)
	main_scene.add_child(card_button)
	
	forced_card_display = card_button
	
	print("Created forced card display for " + card_name + " at 80% scale")

func _create_card_button(texture: ImageTexture, card_name: String, position_index: int):
	"""Creates a clickable card button with the given texture"""
	var card_button = TextureButton.new()
	card_button.texture_normal = texture
	
	# Store metadata
	card_button.set_meta("hand_position", position_index)
	card_button.set_meta("card_name", card_name)
	
	# Set position and size
	card_button.position = _calculate_card_position(position_index)
	card_button.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card_button.scale = CARD_SCALE
	
	#connect hover signals
	card_button.mouse_entered.connect(func(): _on_card_hover_start(card_button))
	card_button.mouse_exited.connect(func(): _on_card_hover_end(card_button))
	
	# Connect click handler
	card_button.pressed.connect(func(): _on_card_clicked(position_index))
	
	# Add to scene
	var main_scene = get_tree().root.get_child(0)
	main_scene.add_child(card_button)
	
	# Track for cleanup
	displayed_cards.append(card_button)
	
	if DEBUG_MODE:
		print("Created card button for " + card_name + " at position " + str(position_index))


func _calculate_card_position(index: int) -> Vector2:
	"""Calculates the screen position for a card at the given index"""
	var x_position = CARD_X_START + (index * CARD_SPACING)
	return Vector2(x_position, CARD_Y_POSITION)


func _on_card_clicked(hand_position: int):
	"""Handles when a card button is clicked"""
	print("Card clicked at hand position: " + str(hand_position))
	
	if gamemgr:
		gamemgr.play_hand_card(hand_position)
	else:
		print("ERROR: Game manager not found!")
		

func _on_card_hover_start(card_button: TextureButton):
	"""Handles when mouse enters a card"""
	# Check if card still exists
	if card_button == null or not is_instance_valid(card_button):
		return
		
	hovered_card = card_button
	# Scale up the card
	card_button.scale = HOVER_SCALE
	# Bring to front
	card_button.z_index = 10	
	
func _on_card_hover_end(card_button: TextureButton):
	"""Handles when mouse leaves a card"""
	if hovered_card == card_button:
		hovered_card = null
	
	# Check if card still exists
	if card_button == null or not is_instance_valid(card_button):
		return
	
	# Scale back down to the stored default scale
	var default_scale = card_button.get_meta("default_scale", CARD_SCALE)
	card_button.scale = default_scale
	# Reset z-index
	card_button.z_index = 0


# ============================================
#            DEBUG FUNCTIONS
#            (For testing only)
# ============================================

func _test_all_card_urls():
	"""Tests all card URLs to verify images exist (debug only)"""
	if not DEBUG_MODE:
		print("Debug mode is disabled. Enable DEBUG_MODE to test URLs.")
		return
	
	print("=== TESTING ALL CARD URLS ===")
	
	if not card_library:
		print("ERROR: Card library not found")
		return
	
	var test_count = 0
	for card in card_library.cards:
		test_count += 1
		_test_single_card_url(card, test_count)
		
		# Small delay to avoid overwhelming the server
		await get_tree().create_timer(0.1).timeout
	
	print("=== STARTED TESTING " + str(test_count) + " CARDS ===")


func _test_single_card_url(card, test_number: int):
	"""Tests a single card URL"""
	var filename = convert_name_to_filename(card.name)
	var url = BASE_URL + filename
	
	print("Testing " + str(test_number) + ": " + card.name + " -> " + filename)
	
	# Create test request
	var http_request = _create_http_request()
	http_request.set_meta("card_name", card.name)
	http_request.set_meta("filename", filename)
	
	# Connect callback
	http_request.request_completed.connect(
		func(result, response_code, headers, body): 
			_test_url_callback(card.name, filename, response_code)
	)
	
	# Make request
	http_request.request(url)


func _test_url_callback(card_name: String, filename: String, response_code: int):
	"""Handles test URL response"""
	if response_code == 200:
		print("✅ SUCCESS: " + card_name + " -> " + filename)
	else:
		print("❌ FAILED (" + str(response_code) + "): " + card_name + " -> " + filename)
	
	# Clean up the test request
	for request in active_requests:
		if request.get_meta("card_name", "") == card_name:
			_cleanup_http_request(request)
			break
