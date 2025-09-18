# File: res://card_library.gd
extends Node

var cards = [
	{"name": "Caloris Basin", "points": 0, "effects": ["add_landmark", "discard_card"]},
	{"name": "Discovery Rupes", "points": 0, "effects": ["add_landmark", "all_players_draw"]},
	{"name": "Io", "points": 0, "effects": ["add_landmark", "points_for_most_landmarks"]},
	{"name": "Enceladus", "points": 0, "effects": ["add_landmark", "draw_if_fewest_landmarks"]},
	{"name": "Sputnik Planitia", "points": 0, "effects": ["add_landmark", "opponent_discards"]},
	{"name": "Cthulhu Macula", "points": 0, "effects": ["add_landmark_2"]},
	{"name": "Gale Crater", "points": 0, "effects": ["add_landmark", "points_if_least_landmarks"]},
	{"name": "Canteloupe Terrain", "points": -2, "effects": ["add_landmark"]},
	{"name": "Solar Streamliner", "points": -1, "effects": ["draw_if_opponent_most_landmarks"]},
	{"name": "Nebula Cruiser", "points": 2, "effects": ["draw_if_most_landmarks"]},
	{"name": "Starlight Zephyr", "points": -1, "effects": ["draw_per_landmark"]},
	{"name": "Aurora Liner", "points": 0, "effects": ["draw_if_most_landmarks_2"]},
	{"name": "Elite Status", "points": 0, "effects": ["win_condition_most_landmarks_2_stars"]},
	{"name": "Cosmic Coupon Run", "points": 0, "effects": ["win_condition_minus_4_points_3_stars"]},
	{"name": "Collector's Cruise", "points": 0, "effects": ["win_condition_most_cards_2_stars"]},
	{"name": "End of the Line", "points": 0, "effects": ["win_condition_deck_runs_out_2_stars"]},
	{"name": "Saturn Ring Speedway", "points": 2, "effects": []},
	{"name": "Jupiter Jazz Club", "points": 3, "effects": []},
	{"name": "Venusian Masquerade", "points": 4, "effects": ["opponent_draws"]},
	{"name": "Martian Mini Golf", "points": 1, "effects": ["draw_card"]},
	{"name": "Interplanetary Circus", "points": 1, "effects": ["opponent_discards"]},
	{"name": "Neptune Aquarium", "points": -6, "effects": ["draw_2_cards"]},
	{"name": "Cosmic Drivein", "points": -1, "effects": []},
	{"name": "Galactic Casino Royale", "points": -2, "effects": []},
	{"name": "Solar Derby", "points": -3, "effects": ["opponent_discards"]}
]
