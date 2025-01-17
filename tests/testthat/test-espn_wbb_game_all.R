
cols <- c("shooting_play", "sequence_number", "home_score", "scoring_play",
          "away_score", "id", "text", "score_value", "period_display_value", "period_number", 
          "coordinate_x", "coordinate_y", "clock_display_value", 
          "team_id", "type_id", "type_text", "play_id", "athlete_id_1", "athlete_id_2")

cols_x2 <- c(
  "game_id", "season", "season_type", "game_date",
  "team_short_display_name", "team_uid",
  "team_alternate_color", "team_color",
  "team_display_name", "team_name", "team_logo",
  "team_location", "team_id", "team_abbreviation",
  "team_slug", "field_goals_made_field_goals_attempted",
  "field_goal_pct",
  "three_point_field_goals_made_three_point_field_goals_attempted",
  "three_point_field_goal_pct", "free_throws_made_free_throws_attempted",
  "free_throw_pct", "total_rebounds", "offensive_rebounds",
  "defensive_rebounds","team_rebounds",
  "assists", "steals", "blocks", "turnovers",
  "team_turnovers", "total_turnovers", "technical_fouls",
  "total_technical_fouls", "flagrant_fouls", 
  "fouls", "largest_lead",
  "home_away", "opponent_id",
  "opponent_name", "opponent_mascot", "opponent_abbrev"
)
test_that("ESPN - WBB Play-by-Play", {
  skip_on_cran()
  x <- espn_wbb_game_all(game_id = 401276115)
  expect_equal(colnames(x$Plays), cols)
  expect_s3_class(x$Plays, "data.frame")
  expect_equal(colnames(x$Team), cols_x2)
  expect_s3_class(x$Team, "data.frame")
})