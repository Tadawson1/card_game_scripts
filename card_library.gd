# File: res://card_library.gd
extends Node

var cards = [
	{"name": "Caloris Basin", "points": 0, "effects": ["add_landmark", "discard"], "effect_params": {"add_landmark": {"amount": 1}, "discard": {"amount": 1}}},
	{"name": "Discovery Rupes", "points": 0, "effects": ["add_landmark", "draw"], "effect_params": {"add_landmark": {"amount": 1}, "draw": {"amount": 1, "target": "all"}}},  # Keep "all" for special handling
	{"name": "Io", "points": 0, "effects": ["add_landmark", "points_conditional"], "effect_params": {"add_landmark": {"amount": 1}, "points_conditional": {"amount": 3, "condition": "most_landmarks"}}},
	{"name": "Enceladus", "points": 0, "effects": ["add_landmark", "draw_conditional"], "effect_params": {"add_landmark": {"amount": 1}, "draw_conditional": {"amount": 1, "condition": "fewest_landmarks"}}},
	{"name": "Sputnik Planitia", "points": 0, "effects": ["add_landmark", "discard"], "effect_params": {"add_landmark": {"amount": 1}, "discard": {"amount": 1}}},
	{"name": "Cthulhu Macula", "points": 0, "effects": ["add_landmark"], "effect_params": {"add_landmark": {"amount": 2}}},
	{"name": "Gale Crater", "points": 0, "effects": ["add_landmark", "points_conditional"], "effect_params": {"add_landmark": {"amount": 1}, "points_conditional": {"amount": 2, "condition": "least_landmarks"}}},
	{"name": "Canteloupe Terrain", "points": -2, "effects": ["add_landmark"], "effect_params": {"add_landmark": {"amount": 1}}},
	{"name": "Solar Streamliner", "points": -1, "effects": ["draw_conditional"], "effect_params": {"draw_conditional": {"amount": 1, "condition": "opponent_most_landmarks"}}},
	{"name": "Nebula Cruiser", "points": 2, "effects": ["draw_conditional"], "effect_params": {"draw_conditional": {"amount": 1, "condition": "most_landmarks"}}},
	{"name": "Starlight Zephyr", "points": -1, "effects": ["draw_conditional"], "effect_params": {"draw_conditional": {"amount": 1, "condition": "per_landmark"}}},
	{"name": "Aurora Liner", "points": 0, "effects": ["draw_conditional"], "effect_params": {"draw_conditional": {"amount": 2, "condition": "most_landmarks"}}},
	{"name": "Elite Status", "points": 0, "effects": ["win_condition_most_landmarks_2_stars"], "requires_target": false},
	{"name": "Cosmic Coupon Run", "points": 0, "effects": ["win_condition_minus_4_points_3_stars"], "requires_target": false},
	{"name": "Collector's Cruise", "points": 0, "effects": ["win_condition_most_cards_2_stars"], "requires_target": false},
	{"name": "End of the Line", "points": 0, "effects": ["win_condition_deck_runs_out_2_stars"], "requires_target": false},
	{"name": "Saturn Ring Speedway", "points": 2, "effects": []},
	{"name": "Jupiter Jazz Club", "points": 3, "effects": []},
	{"name": "Venusian Masquerade", "points": 4, "effects": ["draw"], "effect_params": {"draw": {"amount": 1}}},
	{"name": "Martian Mini Golf", "points": 1, "effects": ["draw"], "effect_params": {"draw": {"amount": 1}}},
	{"name": "Interplanetary Circus", "points": 1, "effects": ["discard"], "effect_params": {"discard": {"amount": 1}}},
	{"name": "Neptune Aquarium", "points": -6, "effects": ["draw"], "effect_params": {"draw": {"amount": 2}}},
	{"name": "Cosmic Drivein", "points": -1, "effects": []},
	{"name": "Galactic Casino Royale", "points": -2, "effects": []},
	{"name": "Solar Derby", "points": -3, "effects": ["discard"], "effect_params": {"discard": {"amount": 1}}}
]
