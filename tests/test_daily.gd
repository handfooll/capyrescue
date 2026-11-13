extends GutTest

## The daily puzzle is local-only: the board comes from the calendar date
## rather than from a server (see the project notes "Backend (Future Phase)" - nothing
## here talks to one), and the streak is a count kept on this device. These
## tests cover the two things that actually have to hold: the same date always
## deals the same board, and the streak advances only on consecutive days.
##
## GameData writes to save_data.test.cfg under a GUT run rather than the
## player's real file, so exercising record_daily_win() here is safe. The tests
## still restore whatever they found, since the daily state is shared across
## the whole suite.

var _saved_last_won: String
var _saved_streak: int

func before_each() -> void:
	_saved_last_won = GameData._daily_last_won
	_saved_streak = GameData._daily_streak

func after_each() -> void:
	GameData._daily_last_won = _saved_last_won
	GameData._daily_streak = _saved_streak

func test_same_date_always_seeds_the_same_puzzle() -> void:
	var first := _generate_for("2026-08-23")
	var second := _generate_for("2026-08-23")
	assert_eq(first.solution, second.solution, "same date must deal the same solution")
	assert_eq(first.regions, second.regions, "same date must deal the same regions")

func test_different_dates_seed_different_puzzles() -> void:
	var today := _generate_for("2026-08-23")
	var tomorrow := _generate_for("2026-08-24")
	assert_ne(today.regions, tomorrow.regions, "consecutive days should not share a board")

func test_daily_seed_is_never_negative() -> void:
	# String.hash() is free to come back with the sign bit set;
	# RandomNumberGenerator.seed doesn't care, but a negative seed leaking into
	# anything index-like would.
	for date in ["2026-01-01", "2026-08-23", "1999-12-31", "2030-06-15"]:
		assert_gte(GameData.daily_seed(date), 0, "seed for %s" % date)

func test_first_win_starts_a_streak_of_one() -> void:
	GameData._daily_last_won = ""
	GameData._daily_streak = 0
	GameData.record_daily_win()
	assert_eq(GameData.daily_streak(), 1)
	assert_true(GameData.is_daily_done_today())

func test_winning_yesterday_then_today_extends_the_streak() -> void:
	GameData._daily_last_won = GameData._day_before(GameData.today_id())
	GameData._daily_streak = 4
	GameData.record_daily_win()
	assert_eq(GameData.daily_streak(), 5)

func test_a_lapsed_streak_restarts_at_one() -> void:
	# Two days ago: the chain is already broken before today's win.
	GameData._daily_last_won = GameData._day_before(GameData._day_before(GameData.today_id()))
	GameData._daily_streak = 9
	GameData.record_daily_win()
	assert_eq(GameData.daily_streak(), 1)

func test_a_lapsed_streak_reads_as_zero_without_being_rewritten() -> void:
	# Nothing runs at midnight to expire a streak, so the expiry has to happen
	# at read time - the stored count stays put until the next win.
	GameData._daily_last_won = GameData._day_before(GameData._day_before(GameData.today_id()))
	GameData._daily_streak = 9
	assert_eq(GameData.daily_streak(), 0)
	assert_eq(GameData._daily_streak, 9, "the stored count shouldn't be clobbered by a read")

func test_replaying_the_same_day_cannot_inflate_the_streak() -> void:
	GameData._daily_last_won = ""
	GameData._daily_streak = 0
	GameData.record_daily_win()
	GameData.record_daily_win()
	GameData.record_daily_win()
	assert_eq(GameData.daily_streak(), 1)

func test_day_before_crosses_month_and_year_boundaries() -> void:
	assert_eq(GameData._day_before("2026-03-01"), "2026-02-28")
	assert_eq(GameData._day_before("2026-01-01"), "2025-12-31")
	assert_eq(GameData._day_before("2024-03-01"), "2024-02-29", "2024 is a leap year")

func _generate_for(date_id: String) -> PuzzleGenerator.GeneratedPuzzle:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameData.daily_seed(date_id)
	var puzzle := PuzzleGenerator.generate(GameData.DAILY_SIZE, 10000, rng)
	assert_not_null(puzzle, "the daily board for %s must actually generate" % date_id)
	return puzzle
