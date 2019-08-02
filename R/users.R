#' List Users
#' https://api.qualtrics.com/reference/list-users
#'
#' @param yourdatacenterid Set in .Renviron
#' @param yourapitoken Set in .Renviron
#' @param responseOnly Return response() object only? Defaults to FALSE.
#'
#' @return Response
#' @import httr glue jsonlite
#' @export
#'
#' @examples
#' \dontrun{
#' listUsers()
#' }
listUsers <- function(yourdatacenterid = Sys.getenv("QUALTRICS_DATACENTERID"), yourapitoken = Sys.getenv("QSI_TOKEN"), responseOnly = FALSE) {
  r <- GET(url = glue::glue("https://{yourdatacenterid}/API/v3/users"), add_headers("X-API-TOKEN" = yourapitoken))
  
  if(responseOnly) {
    return(r)
  } else {
    return(r %>% content("text") %>% fromJSON(simplifyVector = FALSE, simplifyDataFrame = TRUE) %>% .$result %>% .$elements)
  }
}
