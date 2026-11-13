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

## Everyone on the same calendar day gets the same board, because the seed is
## the date - no server hands it out, which is the only reason this can exist
## before the backend question is settled (see the project notes "Backend (Future
## Phase)"): there's nothing to distribute. It also means the streak is a local
## count, not a verified one, and can't survive a reinstall.
const DAILY_SIZE := 6
const SECONDS_PER_DAY := 86400

## Named for the animal that's actually on the board now - the cat-themed
## ladder these replace (Kitten/Cat/Alley Cat/Tiger) was left over from before
## the art switched to capybaras. Same shape of progression: baby, adult,
## oversized, apex.
const DIFFICULTY_NAMES := {
	4: "Pup",
	5: "Capy",
	6: "Chonk",
	7: "King Capy",
}

signal progress_changed

## The difficulty the player is currently on. Started life as a one-shot
## handoff from the level-select screen to the game scene, but the picker now
## lives in Settings (and in the in-game pause card), so it's a persisted
## preference: whatever tier you last chose is what Play gives you next
## launch. Write it through set_pending_size() so it actually saves.
var pending_size: int = 6

## Set by the main menu's Today button just before it opens the game scene, and
## consumed there - the game screen is one scene either way, this is the only
## thing that tells it which of the two it's running.
var pending_daily: bool = false

var _best: Dictionary = {} # size -> {best_time_seconds, best_score, games_played, wins}
var _daily_last_won: String = "" # "YYYY-MM-DD", empty until the first one lands
var _daily_streak: int = 0

func _ready() -> void:
	_load()

static func difficulty_name(size: int) -> String:
	return DIFFICULTY_NAMES.get(size, "%dx%d" % [size, size])

func set_pending_size(size: int) -> void:
	pending_size = clampi(size, MIN_SIZE, MAX_SIZE)
	_save()
	progress_changed.emit()

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
	_daily_last_won = ""
	_daily_streak = 0
	_save()
	progress_changed.emit()

## --- Daily puzzle ------------------------------------------------------

## Local calendar date, "YYYY-MM-DD". Local rather than UTC on purpose: the
## puzzle should turn over at the player's midnight, not somewhere else's.
static func today_id() -> String:
	return Time.get_date_string_from_system(false)

## The seed behind today's board. Hashing the date string (rather than, say,
## using the day number directly) keeps consecutive days from producing
## visibly related layouts.
static func daily_seed(date_id: String = "") -> int:
	var id := date_id if not date_id.is_empty() else today_id()
	return abs(id.hash())

func is_daily_done_today() -> bool:
	return _daily_last_won == today_id()

## Days won back-to-back, ending today or yesterday. A streak that already
## lapsed reads as 0 without needing a write - nothing runs at midnight to
## expire it, so the check has to happen at read time.
func daily_streak() -> int:
	if _daily_last_won.is_empty():
		return 0
	var today := today_id()
	if _daily_last_won == today or _daily_last_won == _day_before(today):
		return _daily_streak
	return 0

## Called when the daily board is solved. Only the first win of the day counts;
## replaying it afterwards can't inflate the streak.
func record_daily_win() -> void:
	var today := today_id()
	if _daily_last_won == today:
		return
	_daily_streak = daily_streak() + 1
	_daily_last_won = today
	_save()
	progress_changed.emit()

## Both directions go through the same "YYYY-MM-DD" <-> unix conversion, so the
## UTC interpretation Time applies to a bare date string cancels out and only
## the day arithmetic survives.
static func _day_before(date_id: String) -> String:
	var stamp := Time.get_unix_time_from_datetime_string(date_id) - SECONDS_PER_DAY
	return Time.get_date_string_from_unix_time(int(stamp))

## True for anything that isn't a real play session - the GUT suite, and the
## dev tools under res://tools/. Both drive the actual game screen and both
## therefore reach record_result()/record_daily_win() exactly as a player
## would, so without this they overwrite the player's real local leaderboard.
## _screenshot_tour.gd in particular solves a board on every run.
static func _is_test_run() -> bool:
	for arg in OS.get_cmdline_args():
		if "gut_cmdln" in arg or arg.begins_with("res://tools/"):
			return true
	return false

func _save_path() -> String:
	return TEST_SAVE_PATH if _is_test_run() else SAVE_PATH

func _load() -> void:
	var config := ConfigFile.new()
	if config.load(_save_path()) != OK:
		return
	# Defaulted rather than assumed present: there's no migration system, so
	# every read has to survive a file written by an older build (the project notes).
	pending_size = clampi(config.get_value("prefs", "size", pending_size), MIN_SIZE, MAX_SIZE)
	_daily_last_won = config.get_value("daily", "last_won", "")
	_daily_streak = maxi(0, config.get_value("daily", "streak", 0))
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
	config.set_value("prefs", "size", pending_size)
	config.set_value("daily", "last_won", _daily_last_won)
	config.set_value("daily", "streak", _daily_streak)
	for size in _best:
		var section := "size_%d" % size
		var entry: Dictionary = _best[size]
		for key in entry:
			config.set_value(section, key, entry[key])
	config.save(_save_path())
