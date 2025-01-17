#' Get ESPN women's college basketball game data (play-by-play, team and player box)
#' @author Saiem Gilani
#' @param game_id Game ID
#' @return A named list of dataframes: Plays, Team, Player
#' @keywords WBB Game
#' @importFrom rlang .data
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr filter select rename bind_cols bind_rows
#' @importFrom tidyr unnest unnest_wider everything
#' @import rvest
#' @export
#' @examples
#' \donttest{
#'   try(espn_wbb_game_all(game_id = 401276115))
#'  }

espn_wbb_game_all <- function(game_id){
  old <- options(list(stringsAsFactors = FALSE, scipen = 999))
  on.exit(options(old))
  
  play_base_url <- "http://cdn.espn.com/womens-college-basketball/playbyplay?render=false&userab=1&xhr=1&"
  
  ## Inputs
  ## game_id
  full_url <- paste0(play_base_url,
                     "gameId=", game_id)
  
  res <- httr::RETRY("GET", full_url)
  
  # Check the result
  check_status(res)
  
  resp <- res %>%
    httr::content(as = "text", encoding = "UTF-8") 
  
  plays_df <- data.frame()
  team_box <- data.frame()
  player_box <- data.frame()
  #---- Play-by-Play ------
  tryCatch(
    expr = {
      raw_play_df <- jsonlite::fromJSON(resp)[["gamepackageJSON"]]
      plays <- raw_play_df[["plays"]]
      plays <- jsonlite::fromJSON(jsonlite::toJSON(plays), flatten=TRUE)
      raw_play_df <- jsonlite::fromJSON(jsonlite::toJSON(raw_play_df),flatten=TRUE)
      
      plays <- plays %>%
        tidyr::unnest_wider(unlist(.data$participants))
      suppressWarnings(
        aths <- plays %>%
          dplyr::group_by(.data$id) %>%
          dplyr::select(.data$id, .data$athlete.id) %>%
          tidyr::unnest_wider(unlist(.data$athlete.id, use.names=FALSE),names_sep = ".")
      )
      names(aths)<-c("play.id","athlete.id.1","athlete.id.2")
      plays_df <- dplyr::bind_cols(plays, aths) %>%
        select(-.data$athlete.id)
      
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no play-by-play data for {game_id} available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  #---- Team Box ------
  tryCatch(
    expr = {
      raw_play_df <- jsonlite::fromJSON(resp)[["gamepackageJSON"]]
      season <- raw_play_df[['header']][['season']][['year']]
      season_type <- raw_play_df[['header']][['season']][['type']]
      homeAwayTeam1 = toupper(raw_play_df[['header']][['competitions']][['competitors']][[1]][['homeAway']][1])
      homeAwayTeam2 = toupper(raw_play_df[['header']][['competitions']][['competitors']][[1]][['homeAway']][2])
      homeTeamId = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['id']][1]
      awayTeamId = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['id']][2]
      homeTeamMascot = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['name']][1]
      awayTeamMascot = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['name']][2]
      homeTeamName = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['location']][1]
      awayTeamName = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['location']][2]
      
      homeTeamAbbrev = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['abbreviation']][1]
      awayTeamAbbrev = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['abbreviation']][2]
      game_date = as.Date(substr(raw_play_df[['header']][['competitions']][['date']],0,10))
      
      teams_box_score_df <- jsonlite::fromJSON(jsonlite::toJSON(raw_play_df[["boxscore"]][["teams"]]),flatten=TRUE)
      
      teams_box_score_df_2 <- teams_box_score_df[[1]][[2]] %>%
        dplyr::select(.data$displayValue, .data$name) %>%
        dplyr::rename(Home = .data$displayValue)
      teams_box_score_df_1 <- teams_box_score_df[[1]][[1]] %>%
        dplyr::select(.data$displayValue, .data$name) %>%
        dplyr::rename(Away = .data$displayValue)
      teams2 <- data.frame(t(teams_box_score_df_2$Home))
      colnames(teams2) <- t(teams_box_score_df_2$name)
      teams2$homeAway <- homeAwayTeam2
      teams2$OpponentId <- as.integer(awayTeamId)
      teams2$OpponentName <- awayTeamName
      teams2$OpponentMascot <- awayTeamMascot
      teams2$OpponentAbbrev <- awayTeamAbbrev
      
      teams1 <- data.frame(t(teams_box_score_df_1$Away))
      colnames(teams1) <- t(teams_box_score_df_1$name)
      teams1$homeAway <- homeAwayTeam1
      teams1$OpponentId <- as.integer(homeTeamId)
      teams1$OpponentName <- homeTeamName
      teams1$OpponentMascot <- homeTeamMascot
      teams1$OpponentAbbrev <- homeTeamAbbrev
      teams <- dplyr::bind_rows(teams1,teams2)
      
      team_box_score <- teams_box_score_df %>%
        dplyr::select(-.data$statistics) %>%
        dplyr::bind_cols(teams)
      
      team_box_score <- team_box_score %>%
        dplyr::mutate(
          game_id = game_id,
          season = season,
          season_type = season_type,
          game_date = game_date
        ) %>%
        janitor::clean_names() %>%
        dplyr::select(
          .data$game_id,
          .data$season,
          .data$season_type,
          .data$game_date,
          tidyr::everything()
        )
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no team box score data for {game_id} available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  #---- Player Box ------
  tryCatch(
    expr = {
      raw_play_df <- jsonlite::fromJSON(resp)[["gamepackageJSON"]]
      players_df <- jsonlite::fromJSON(jsonlite::toJSON(raw_play_df[["boxscore"]][["players"]]), flatten=TRUE) %>%
        tidyr::unnest(.data$statistics) %>%
        tidyr::unnest(.data$athletes)
      stat_cols <- players_df$names[[1]]
      stats <- players_df$stats
      
      stats_df <- as.data.frame(do.call(rbind,stats))
      colnames(stats_df) <- stat_cols
      
      players_df <- players_df %>%
        dplyr::filter(!.data$didNotPlay) %>%
        dplyr::select(.data$starter,.data$ejected, .data$didNotPlay,.data$active,
                      .data$athlete.displayName,.data$athlete.jersey,
                      .data$athlete.id,.data$athlete.shortName,
                      .data$athlete.headshot.href,.data$athlete.position.name,
                      .data$athlete.position.abbreviation,.data$team.shortDisplayName,
                      .data$team.name,.data$team.logo,.data$team.id,.data$team.abbreviation,
                      .data$team.color,.data$team.alternateColor
        )
      
      player_box <- dplyr::bind_cols(stats_df,players_df) %>%
        dplyr::select(.data$athlete.displayName,.data$team.shortDisplayName, tidyr::everything())
      plays_df <- plays_df %>% 
        janitor::clean_names()
      team_box_score <- team_box_score %>% 
        janitor::clean_names()
      player_box <- player_box %>% 
        janitor::clean_names() %>% 
        dplyr::rename(
          fg3 = .data$x3pt
        )
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no player box score data for {game_id} available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  
  pbp <- c(list(plays_df), list(team_box_score),list(player_box))
  names(pbp) <- c("Plays","Team","Player")
  return(pbp)
}

#' Get ESPN women's college basketball play by play data
#' @author Saiem Gilani
#' @param game_id Game ID
#' @return Returns a play-by-play data frame
#' @keywords WBB PBP
#' @importFrom rlang .data
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr filter select rename bind_cols bind_rows
#' @importFrom tidyr unnest unnest_wider everything
#' @import rvest
#' @export
#' @examples
#' \donttest{
#'   try(espn_wbb_pbp(game_id = 401276115))
#' }
espn_wbb_pbp <- function(game_id){
  old <- options(list(stringsAsFactors = FALSE, scipen = 999))
  on.exit(options(old))
  
  play_base_url <- "http://cdn.espn.com/womens-college-basketball/playbyplay?render=false&userab=1&xhr=1&"
  
  plays_df <- data.frame()
  
  ## Inputs
  ## game_id
  full_url <- paste0(play_base_url,
                     "gameId=", game_id)
  
  res <- httr::RETRY("GET", full_url)
  
  # Check the result
  check_status(res)
  
  resp <- res %>%
    httr::content(as = "text", encoding = "UTF-8") 
  
  tryCatch(
    expr = {
      raw_play_df <- jsonlite::fromJSON(resp)[["gamepackageJSON"]][["plays"]]
      
      raw_play_df <- jsonlite::fromJSON(jsonlite::toJSON(raw_play_df),flatten=TRUE)
      #---- Play-by-Play ------
      plays <- raw_play_df %>%
        tidyr::unnest_wider(unlist(.data$participants))
      suppressWarnings(
        aths <- plays %>%
          dplyr::group_by(.data$id) %>%
          dplyr::select(.data$id, .data$athlete.id) %>%
          tidyr::unnest_wider(unlist(.data$athlete.id, use.names=FALSE),names_sep = ".")
      )
      names(aths)<-c("play.id","athlete.id.1","athlete.id.2")
      plays_df <- dplyr::bind_cols(plays, aths) %>%
        select(-.data$athlete.id)
      plays_df <- plays_df %>% 
        janitor::clean_names()
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no play-by-play data for {game_id} available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  
  return(plays_df)
}
#' Get ESPN women's college basketball team box data 
#' @author Saiem Gilani
#' @param game_id Game ID
#' @return Returns a team boxscore data frame
#' @keywords WBB Team Box
#' @importFrom rlang .data
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr filter select rename bind_cols bind_rows
#' @importFrom tidyr unnest unnest_wider everything
#' @import rvest
#' @export
#' @examples
#' \donttest{
#'   try(espn_wbb_team_box(game_id = 401276115))
#' }
espn_wbb_team_box <- function(game_id){
  old <- options(list(stringsAsFactors = FALSE, scipen = 999))
  on.exit(options(old))
  play_base_url <- "http://cdn.espn.com/womens-college-basketball/playbyplay?render=false&userab=1&xhr=1&"
  
  full_url <- paste0(play_base_url,
                     "gameId=", game_id)
  
  res <- httr::RETRY("GET", full_url)
  
  # Check the result
  check_status(res)
  
  resp <- res %>%
    httr::content(as = "text", encoding = "UTF-8") 
  
  #---- Team Box ------
  tryCatch(
    expr = {
      raw_play_df <- jsonlite::fromJSON(resp)[["gamepackageJSON"]]
      season <- raw_play_df[['header']][['season']][['year']]
      season_type <- raw_play_df[['header']][['season']][['type']]
      homeAwayTeam1 = toupper(raw_play_df[['header']][['competitions']][['competitors']][[1]][['homeAway']][1])
      homeAwayTeam2 = toupper(raw_play_df[['header']][['competitions']][['competitors']][[1]][['homeAway']][2])
      homeTeamId = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['id']][1]
      awayTeamId = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['id']][2]
      homeTeamMascot = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['name']][1]
      awayTeamMascot = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['name']][2]
      homeTeamName = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['location']][1]
      awayTeamName = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['location']][2]
      
      homeTeamAbbrev = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['abbreviation']][1]
      awayTeamAbbrev = raw_play_df[['header']][['competitions']][['competitors']][[1]][['team']][['abbreviation']][2]
      game_date = as.Date(substr(raw_play_df[['header']][['competitions']][['date']],0,10))
      
      teams_box_score_df <- jsonlite::fromJSON(jsonlite::toJSON(raw_play_df[["boxscore"]][["teams"]]),flatten=TRUE)
      
      teams_box_score_df_2 <- teams_box_score_df[[1]][[2]] %>%
        dplyr::select(.data$displayValue, .data$name) %>%
        dplyr::rename(Home = .data$displayValue)
      teams_box_score_df_1 <- teams_box_score_df[[1]][[1]] %>%
        dplyr::select(.data$displayValue, .data$name) %>%
        dplyr::rename(Away = .data$displayValue)
      teams2 <- data.frame(t(teams_box_score_df_2$Home))
      colnames(teams2) <- t(teams_box_score_df_2$name)
      teams2$homeAway <- homeAwayTeam2
      teams2$OpponentId <- as.integer(awayTeamId)
      teams2$OpponentName <- awayTeamName
      teams2$OpponentMascot <- awayTeamMascot
      teams2$OpponentAbbrev <- awayTeamAbbrev
      
      teams1 <- data.frame(t(teams_box_score_df_1$Away))
      colnames(teams1) <- t(teams_box_score_df_1$name)
      teams1$homeAway <- homeAwayTeam1
      teams1$OpponentId <- as.integer(homeTeamId)
      teams1$OpponentName <- homeTeamName
      teams1$OpponentMascot <- homeTeamMascot
      teams1$OpponentAbbrev <- homeTeamAbbrev
      teams <- dplyr::bind_rows(teams1,teams2)
      
      team_box_score <- teams_box_score_df %>%
        dplyr::select(-.data$statistics) %>%
        dplyr::bind_cols(teams)
      
      team_box_score <- team_box_score %>%
        dplyr::mutate(
          game_id = game_id,
          season = season,
          season_type = season_type,
          game_date = game_date
        ) %>%
        janitor::clean_names() %>%
        dplyr::select(
          .data$game_id,
          .data$season,
          .data$season_type,
          .data$game_date,
          tidyr::everything()
        )
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no team box score data for {game_id} available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  return(team_box_score)
}
#' Get ESPN women's college basketball player box
#' @author Saiem Gilani
#' @param game_id Game ID
#' @return Returns a player boxscore data frame
#' @keywords WBB Player Box
#' @importFrom rlang .data
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr filter select rename bind_cols bind_rows
#' @importFrom tidyr unnest unnest_wider everything
#' @import rvest
#' @export
#' @examples
#' \donttest{
#'   try(espn_wbb_player_box(game_id = 401276115))
#' }
espn_wbb_player_box <- function(game_id){
  old <- options(list(stringsAsFactors = FALSE, scipen = 999))
  on.exit(options(old))
  play_base_url <- "http://cdn.espn.com/womens-college-basketball/playbyplay?render=false&userab=1&xhr=1&"
  
  ## Inputs
  ## game_id
  full_url <- paste0(play_base_url,
                     "gameId=", game_id)
  
  res <- httr::RETRY("GET", full_url)
  
  # Check the result
  check_status(res)
  
  resp <- res %>%
    httr::content(as = "text", encoding = "UTF-8")
  
  #---- Player Box ------
  tryCatch(
    expr = {
      raw_play_df <- jsonlite::fromJSON(resp)[["gamepackageJSON"]]
      raw_play_df <- jsonlite::fromJSON(jsonlite::toJSON(raw_play_df),flatten=TRUE)
      players_df <- jsonlite::fromJSON(jsonlite::toJSON(raw_play_df[["boxscore"]][["players"]]), flatten=TRUE) %>%
        tidyr::unnest(.data$statistics) %>%
        tidyr::unnest(.data$athletes)
      stat_cols <- players_df$names[[1]]
      stats <- players_df$stats
      
      stats_df <- as.data.frame(do.call(rbind,stats))
      colnames(stats_df) <- stat_cols
      
      players_df <- players_df %>%
        dplyr::filter(!.data$didNotPlay) %>%
        dplyr::select(.data$starter,.data$ejected, .data$didNotPlay,.data$active,
                      .data$athlete.displayName,.data$athlete.jersey,
                      .data$athlete.id,.data$athlete.shortName,
                      .data$athlete.headshot.href,.data$athlete.position.name,
                      .data$athlete.position.abbreviation,.data$team.shortDisplayName,
                      .data$team.name,.data$team.logo,.data$team.id,.data$team.abbreviation,
                      .data$team.color,.data$team.alternateColor
        )
      
      player_box <- dplyr::bind_cols(stats_df,players_df) %>%
        dplyr::select(.data$athlete.displayName,.data$team.shortDisplayName, tidyr::everything())
      player_box <- player_box %>% 
        janitor::clean_names() %>% 
        dplyr::rename(
          fg3 = .data$x3pt
        )
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no player box score data for {game_id} available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  return(player_box)
}


#' Get women's college basketball conferences
#'
#' @author Saiem Gilani
#' @return Returns a tibble
#' @importFrom jsonlite fromJSON
#' @importFrom janitor clean_names
#' @importFrom dplyr select
#' @import rvest
#' @export
#' @examples
#' \donttest{
#'   try(espn_wbb_conferences())
#' }
espn_wbb_conferences <- function(){
  old <- options(list(stringsAsFactors = FALSE, scipen = 999))
  on.exit(options(old))
  play_base_url <- "http://site.api.espn.com/apis/site/v2/sports/basketball/womens-college-basketball/scoreboard/conferences"
  
  res <- httr::RETRY("GET", play_base_url)
  
  # Check the result
  check_status(res)
  
  resp <- res %>%
    httr::content(as = "text", encoding = "UTF-8") 
  tryCatch(
    expr = {
      conferences <- jsonlite::fromJSON(resp)[["conferences"]] %>%
        dplyr::select(-.data$subGroups) %>%
        janitor::clean_names()
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no conferences info available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  return(conferences)
}

#' Get ESPN women's college basketball team names and ids
#' @author Saiem Gilani
#' @return Returns a teams infomation data frame
#' @keywords WBB Teams
#' @importFrom rlang .data
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr filter select rename bind_cols bind_rows row_number group_by mutate as_tibble ungroup
#' @importFrom tidyr unnest unnest_wider everything pivot_wider
#' @import rvest
#' @import furrr
#' @export
#'
#' @examples
#' \donttest{
#'   try(espn_wbb_teams())
#' }

espn_wbb_teams <- function(){
  old <- options(list(stringsAsFactors = FALSE, scipen = 999))
  on.exit(options(old))
  play_base_url <- "http://site.api.espn.com/apis/site/v2/sports/basketball/womens-college-basketball/teams?groups=50&limit=1000"
  
  res <- httr::RETRY("GET", play_base_url)
  
  # Check the result
  check_status(res)
  
  resp <- res %>%
    httr::content(as = "text", encoding = "UTF-8") 
  
  tryCatch(
    expr = {
      
      leagues <- jsonlite::fromJSON(resp)[["sports"]][["leagues"]][[1]][['teams']][[1]][['team']] %>%
        dplyr::group_by(.data$id) %>%
        tidyr::unnest_wider(unlist(.data$logos, use.names=FALSE),names_sep = "_") %>%
        tidyr::unnest_wider(.data$logos_href,names_sep = "_") %>%
        dplyr::select(-.data$logos_width,-.data$logos_height,
                      -.data$logos_alt, -.data$logos_rel) %>%
        dplyr::ungroup()
      
      if("records" %in% colnames(leagues)){
        records <- leagues$record
        records<- records %>% tidyr::unnest_wider(.data$items) %>%
          tidyr::unnest_wider(.data$stats,names_sep = "_") %>%
          dplyr::mutate(row = dplyr::row_number())
        stat <- records %>%
          dplyr::group_by(.data$row) %>%
          purrr::map_if(is.data.frame, list)
        stat <- lapply(stat$stats_1,function(x) x %>%
                         purrr::map_if(is.data.frame,list) %>%
                         dplyr::as_tibble())
        
        s <- lapply(stat, function(x) {
          tidyr::pivot_wider(x)
        })
        
        s <- tibble::tibble(g = s)
        stats <- s %>% unnest_wider(.data$g)
        
        records <- dplyr::bind_cols(records %>% dplyr::select(.data$summary), stats)
        leagues <- leagues %>% dplyr::select(
          -.data$record
        )
      }
      leagues <- leagues %>% dplyr::select(
        -.data$links,
        -.data$isActive,
        -.data$isAllStar,
        -.data$uid,
        -.data$slug,
        -.data$record,
        -.data$logos_lastUpdated)
      teams <- leagues %>% 
        dplyr::rename(
          logo = .data$logos_href_1,
          logo_dark = .data$logos_href_2,
          mascot = .data$name,
          team = .data$location,
          team_id = .data$id,
          short_name = .data$shortDisplayName,
          alternate_color = .data$alternateColor,
          display_name = .data$displayName
        )
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no teams data available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  return(teams)
}


#' Get women's college basketball schedule for a specific year from ESPN's API
#'
#' @param season Either numeric or character
#' @author Saiem Gilani
#' @return Returns a tibble
#' @import utils
#' @import rvest
#' @import furrr
#' @importFrom dplyr select rename any_of mutate
#' @importFrom jsonlite fromJSON
#' @importFrom tidyr unnest_wider unchop hoist
#' @importFrom glue glue
#' @export
#' @examples
#' # Get schedule returns 1000 results, max allowable.
#' # Get schedule from date 2021-02-15, then next date and so on.
#' \donttest{
#'   try(espn_wbb_scoreboard (season = "20210215"))
#' }

espn_wbb_scoreboard <- function(season){
  
  max_year <- substr(Sys.Date(), 1,4)
  
  if(!(as.integer(substr(season, 1, 4)) %in% c(2001:max_year))){
    message(paste("Error: Season must be between 2001 and", max_year))
  }
  
  # year > 2000
  season <- as.character(season)
  
  season_dates <- season
  
  schedule_api <- glue::glue("http://site.api.espn.com/apis/site/v2/sports/basketball/womens-college-basketball/scoreboard?groups=50&limit=1000&dates={season_dates}")
  
  res <- httr::RETRY("GET", schedule_api)
  
  # Check the result
  check_status(res)
  
  tryCatch(
    expr = {
      raw_sched <- res %>%
        httr::content(as = "text", encoding = "UTF-8") %>%
        jsonlite::fromJSON(simplifyDataFrame = FALSE, simplifyVector = FALSE, simplifyMatrix = FALSE)
      
      
      wbb_data <- raw_sched[["events"]] %>%
        tibble::tibble(data = .data$.) %>%
        tidyr::unnest_wider(.data$data) %>%
        tidyr::unchop(.data$competitions) %>%
        dplyr::select(-.data$id, -.data$uid, -.data$date, -.data$status) %>%
        tidyr::unnest_wider(.data$competitions) %>%
        dplyr::rename(matchup = .data$name, matchup_short = .data$shortName, game_id = .data$id, game_uid = .data$uid, game_date = .data$date) %>%
        tidyr::hoist(.data$status,
                     status_name = list("type", "name")) %>%
        dplyr::select(!dplyr::any_of(c("timeValid", "recent", "venue", "type"))) %>%
        tidyr::unnest_wider(.data$season) %>%
        dplyr::rename(season = .data$year) %>%
        dplyr::select(-dplyr::any_of("status")) %>%
        tidyr::hoist(
          .data$competitors,
          home_team_name = list(1, "team", "name"),
          home_team_logo = list(1, "team", "logo"),
          home_team_abbreviation = list(1, "team", "abbreviation"),
          home_team_id = list(1, "team", "id"),
          home_team_location = list(1, "team", "location"),
          home_team_full_name = list(1, "team", "displayName"),
          home_team_color = list(1, "team", "color"),
          home_score = list(1, "score"),
          home_win = list(1, "winner"),
          home_record = list(1, "records", 1, "summary"),
          # away team
          away_team_name = list(2, "team", "name"),
          away_team_logo = list(2, "team", "logo"),
          away_team_abbreviation = list(2, "team", "abbreviation"),
          away_team_id = list(2, "team", "id"),
          away_team_location = list(2, "team", "location"),
          away_team_full_name = list(2, "team", "displayName"),
          away_team_color = list(2, "team", "color"),
          away_score = list(2, "score"),
          away_win = list(2, "winner"),
          away_record = list(2, "records", 1, "summary")) %>%
        dplyr::mutate(
          home_win = as.integer(.data$home_win),
          away_win = as.integer(.data$away_win),
          home_score = as.integer(.data$home_score),
          away_score = as.integer(.data$away_score))
      
      if("broadcasts" %in% names(wbb_data)) {
        wbb_data %>%
          tidyr::hoist(
            .data$broadcasts,
            broadcast_market = list(1, "market"),
            broadcast_name = list(1, "names", 1)) %>%
          dplyr::select(!where(is.list)) %>% 
          janitor::clean_names()
      } else {
        wbb_data %>% 
          dplyr::select(!where(is.list)) %>% 
          janitor::clean_names()
      }
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no scoreboard data available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
}

#' @import utils
utils::globalVariables(c("where"))

#' Get Women's college basketball NET rankings for the current date from the NCAA website
#'
#' @author Saiem Gilani
#' @return Returns a tibble
#' @importFrom dplyr %>% as_tibble
#' @import rvest
#' @export
#' @examples
#' # Get current NCAA NET rankings
#' \donttest{
#'   try(ncaa_wbb_NET_rankings())
#' }

ncaa_wbb_NET_rankings <- function(){
  
  
  NET_url <- "https://www.ncaa.com/rankings/basketball-women/d1/ncaa-womens-basketball-net-rankings"
  tryCatch(
    expr = {
      x <- (NET_url %>%
              xml2::read_html() %>%
              rvest::html_nodes("table"))[[1]] %>%
        rvest::html_table(fill=TRUE) %>%
        dplyr::as_tibble() %>% 
        janitor::clean_names()
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no NET rankings available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  return(x)
}


#' Get women's college basketball AP and Coaches poll rankings
#'
#' @author Saiem Gilani
#' @return Returns a tibble
#' @importFrom dplyr %>%  bind_rows arrange select
#' @importFrom jsonlite fromJSON
#' @importFrom tidyr unnest
#' @import rvest
#' @export
#' @examples
#' # Get current AP and Coaches Poll rankings
#' \donttest{
#'   try(espn_wbb_rankings())
#' }

espn_wbb_rankings <- function(){
  old <- options(list(stringsAsFactors = FALSE, scipen = 999))
  on.exit(options(old))
  
  ranks_url <- "http://site.api.espn.com/apis/site/v2/sports/basketball/womens-college-basketball/rankings?groups=50"
  
  res <- httr::RETRY("GET", ranks_url)
  
  # Check the result
  check_status(res)
  
  resp <- res %>%
    httr::content(as = "text", encoding = "UTF-8") 
  tryCatch(
    expr = {
      
      ranks_df <- jsonlite::fromJSON(resp,flatten = TRUE)[['rankings']]
      ranks_top25 <- ranks_df %>%
        dplyr::select(-.data$date,-.data$lastUpdated) %>%
        tidyr::unnest(.data$ranks, names_repair="minimal") 
      ranks_others <- ranks_df %>%
        dplyr::select(-.data$date,-.data$lastUpdated) %>% 
        tidyr::unnest(.data$others, names_repair="minimal") 
      ranks_dropped_out <- ranks_df %>%
        dplyr::select(-.data$date,-.data$lastUpdated) %>%
        tidyr::unnest(.data$droppedOut, names_repair="minimal") 
      
      ranks <- dplyr::bind_rows(ranks_top25, ranks_others, ranks_dropped_out)
      drop_cols <- c(
        "$ref", "team.links","season.powerIndexes.$ref",
        "season.powerIndexLeaders.$ref", "season.athletes.$ref",
        "season.leaders.$ref","season.powerIndexLeaders.$ref",
        "others","droppedOut","ranks"
      )
      ranks <- ranks  %>%
        dplyr::select(-dplyr::any_of(drop_cols))
      ranks <- ranks %>% dplyr::arrange(.data$name,-.data$points) %>% 
        janitor::clean_names()
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no rankings data for {game_id} available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
  )
  
  return(ranks)
} 



#' Get ESPN women's college basketball standings
#'
#' @param year Either numeric or character (YYYY)
#' @return Returns a tibble
#' @keywords WBB Standings
#' @importFrom rlang .data
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom dplyr select rename
#' @importFrom tidyr pivot_wider
#' @export
#' @examples
#' \donttest{
#'   try(espn_wbb_standings(2021))
#'  }
espn_wbb_standings <- function(year){
  
  standings_url <- "https://site.web.api.espn.com/apis/v2/sports/basketball/womens-college-basketball/standings?region=us&lang=en&contentorigin=espn&type=0&level=1&sort=winpercent%3Adesc%2Cwins%3Adesc%2Cgamesbehind%3Aasc&"
  
  ## Inputs
  ## year
  full_url <- paste0(standings_url,
                     "season=", year)
  
  res <- httr::RETRY("GET", full_url)
  
  # Check the result
  check_status(res)
  tryCatch(
    expr = {
      resp <- res %>%
        httr::content(as = "text", encoding = "UTF-8")
      
      raw_standings <- jsonlite::fromJSON(resp)[["standings"]]
      
      #Create a dataframe of all WBB teams by extracting from the raw_standings file
      
      teams <- raw_standings[["entries"]][["team"]]
      
      teams <- teams %>%
        dplyr::select(.data$id, .data$displayName) %>%
        dplyr::rename(team_id = .data$id,
                      team = .data$displayName)
      
      #creating a dataframe of the WNBA raw standings table from ESPN
      
      standings_df <- raw_standings[["entries"]][["stats"]]
      
      standings_data <- data.table::rbindlist(standings_df, fill = TRUE, idcol = T)
      
      #Use the following code to replace NA's in the dataframe with the correct corresponding values and removing all unnecessary columns
      
      standings_data$value <- ifelse(is.na(standings_data$value) & !is.na(standings_data$summary), standings_data$summary, standings_data$value)
      
      standings_data <- standings_data %>%
        dplyr::select(.data$.id, .data$type, .data$value)
      
      #Use pivot_wider to transpose the dataframe so that we now have a standings row for each team
      
      standings_data <- standings_data %>%
        tidyr::pivot_wider(names_from = .data$type, values_from = .data$value)
      
      
      standings_data <- standings_data %>%
        dplyr::select(-.data$.id)
      
      #joining the 2 dataframes together to create a standings table
      
      standings <- cbind(teams, standings_data)
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no standings data available!"))
    },
    warning = function(w) {
    },
    finally = {
    }
    
  )
  return(standings)
}