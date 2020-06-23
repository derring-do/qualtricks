#' List Users
#' https://api.qualtrics.com/docs/managing-users#list-users
#'
#' @param yourdatacenterid Set in .Renviron
#' @param yourapitoken Set in .Renviron
#' @param offset paging, defaults to 0 (first page only)
#' @param responseOnly Return response() object only? Defaults to FALSE.
#'
#' @return Response or data.frame
#' @import httr glue jsonlite
#' @export
#'
#' @examples
#' \dontrun{
#' listUsers()
#' listUsers(offset=100)
#' lapply(seq(0,600,100), function(x) { listUsers(offset=x) }) %>% rbindlist
#' }
listUsers <- function(yourdatacenterid = Sys.getenv("QUALTRICS_DATACENTERID"),
                      yourapitoken = Sys.getenv("QSI_TOKEN"),
                      offset = 0,
                      responseOnly = FALSE) {

  r <- GET(url = glue::glue("https://{yourdatacenterid}/API/v3/users"),
           query = list(offset = offset),
           add_headers("X-API-TOKEN" = yourapitoken))

  if(responseOnly) {
    return(r)
  } else {
    return(r %>% content("text") %>% fromJSON(simplifyVector = FALSE, simplifyDataFrame = TRUE) %>% .$result %>% .$elements)
  }
}

#' Get User API Token
#'
#' @param userId
#' @param yourdatacenterid
#' @param yourapitoken
#'
#' @return the api token or error message if token already exists
#' @export
#'
#' @examples
#' getUserAPIToken("")
getUserAPIToken <- function(userId,
                            yourdatacenterid = Sys.getenv("QUALTRICS_DATACENTERID"),
                            yourapitoken = Sys.getenv("QSI_TOKEN")) {
  r <- GET(url = paste0("https://", yourdatacenterid, "/API/v3/users/", userId, "/apitoken"),
           add_headers("X-API-TOKEN" = yourapitoken)
  )
  return(content(r)$result)
}

#' Create User API Token
#'
#' @param userId
#' @param yourdatacenterid
#' @param yourapitoken
#'
#' @return response
#' @export
#'
#' @examples
#' createUserAPIToken("")
createUserAPIToken <- function(userId,
                               yourdatacenterid = Sys.getenv("QUALTRICS_DATACENTERID"),
                               yourapitoken = Sys.getenv("QSI_TOKEN")) {
  r <- POST(url = paste0("https://", yourdatacenterid, "/API/v3/users/", userId, "/apitoken"),
            add_headers("X-API-TOKEN" = yourapitoken)
  )
  return(r)
  # returns error if token already generated
}

