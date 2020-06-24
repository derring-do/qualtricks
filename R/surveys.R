#' List Surveys
#' https://api.qualtrics.com/guides/reference/surveys.json/paths/~1surveys/get
#'
#' @param yourdatacenterid Set in .Renviron
#' @param yourapitoken Set in .Renviron
#' @param offset paging, defaults to 0 (first page only)
#' @param responseOnly Return response() object only? Defaults to FALSE.
#'
#' @return Response or data.frame
#' @import httr glue jsonlite dplyr
#' @export
#'
#' @examples
#' \dontrun{
#' a <- listSurveys()
#' listSurveys(responseOnly=TRUE)
#' a
#' dim(a)
#' b <- lapply(seq(0,1000,100), function(x) { listSurveys(offset=x) }) %>% bind_rows
#' dim(b)
#' }
listSurveys <- function(yourdatacenterid = Sys.getenv("QUALTRICS_DATACENTERID"),
                      yourapitoken = Sys.getenv("QSI_TOKEN"),
                      offset = 0,
                      responseOnly = FALSE) {

  r <- GET(url = glue::glue("https://{yourdatacenterid}/API/v3/surveys"),
           query = list(offset = offset),
           add_headers("X-API-TOKEN" = yourapitoken))

  if(responseOnly) {
    return(r)
  } else {
    return(r %>% content("text") %>% fromJSON(simplifyVector = FALSE, simplifyDataFrame = TRUE) %>% .$result %>% .$elements)
  }
}

#' List All Surveys
#'
#' @param ... args for listSurveys
#'
#' @description like listSurveys but does the pagination
#' @return
#' @export
#'
#' @examples
#' listAllSurveys()
listAllSurveys <- function(...) {
  resp <- listSurveys(responseOnly = TRUE)
  master <- c()

  master <- append(master, list(listSurveys()))

  while (!is.null(content(resp)$result$nextPage)) {
    # Send GET request to list all surveys
    offset <- strsplit(content(resp)$result$nextPage, "offset=")[[1]][2]
    resp <- listSurveys(offset=offset, responseOnly=TRUE)
    # Append results
    master <- append(master, list(resp%>% content("text") %>% fromJSON(simplifyVector = FALSE, simplifyDataFrame = TRUE) %>% .$result %>% .$elements))
  }

  return(bind_rows(master))
}

