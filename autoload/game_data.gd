extends Node

## Local progress: per-difficulty best time/score and play counts, plus the
## size chosen on the level-select screen so the game scene knows what to
## load when it's opened via `change_scene_to_file`. Autoloaded as
## "GameData". No backend yet (see the project notes "Backend (Future Phase)") - this
## is pure on-device persistence via ConfigFile, same mechanism as Settings.

const SAVE_PATH := "user://save_data.cfg"
# GUT's test_main_ui.gd plays real games through the actual game screen
# (solving via request_hint()), which calls record_result() same as a real
# player would - without this redirect, every `gut_cmdln.gd` run quietly
# overwrites the player's real local leaderboard with test data. Detected via
# the same command line GUT is documented to run under in the project notes.
const TEST_SAVE_PATH := "user://save_data.test.cfg"
const STARTING_LIVES := 3
const MIN_SIZE := 4
const MAX_SIZE := 7

const DIFFICULTY_NAMES := {
	4: "Kitten",
	5: "Cat",
	6: "Alley Cat",
	7: "Tiger",
}

signal progress_changed

## Size the level-select screen picked; the game screen reads this in
## _ready() and clears it isn't meaningful outside that one handoff.
var pending_size: int = 6

var _best: Dictionary = {} # size -> {best_time_seconds, best_score, games_played, wins}

func _ready() -> void:
	_load()

static func difficulty_name(size: int) -> String:
	return DIFFICULTY_NAMES.get(size, "%dx%d" % [size, size])

func get_best(size: int) -> Dictionary:
	return _best.get(size, {
		"best_time_seconds": -1.0,
		"best_score": 0,
		"games_played": 0,
		"wins": 0,
	})

## Records a finished game (win or loss). Returns true if this run set a new
## best score for the difficulty.
func record_result(size: int, time_seconds: float, score: int, won: bool) -> bool:
	var entry: Dictionary = get_best(size)
	entry.games_played += 1
	if won:
		entry.wins += 1
	var is_new_best := false
	if won and score > entry.best_score:
		entry.best_score = score
		is_new_best = true
	if won and (entry.best_time_seconds < 0.0 or time_seconds < entry.best_time_seconds):
		entry.best_time_seconds = time_seconds
	_best[size] = entry
	_save()
	progress_changed.emit()
	return is_new_best

func reset_progress() -> void:
	_best.clear()
	_save()
	progress_changed.emit()

static func _is_test_run() -> bool:
	for arg in OS.get_cmdline_args():
		if "gut_cmdln" in arg:
			return true
	return false

func _save_path() -> String:
	return TEST_SAVE_PATH if _is_test_run() else SAVE_PATH

func _load() -> void:
	var config := ConfigFile.new()
	if config.load(_save_path()) != OK:
		return
	for size in range(MIN_SIZE, MAX_SIZE + 1):
		var section := "size_%d" % size
		if not config.has_section(section):
			continue
		_best[size] = {
			"best_time_seconds": config.get_value(section, "best_time_seconds", -1.0),
			"best_score": config.get_value(section, "best_score", 0),
			"games_played": config.get_value(section, "games_played", 0),
			"wins": config.get_value(section, "wins", 0),
		}

func _save() -> void:
	var config := ConfigFile.new()
	for size in _best:
		var section := "size_%d" % size
		var entry: Dictionary = _best[size]
		for key in entry:
			config.set_value(section, key, entry[key])
	config.save(_save_path())
