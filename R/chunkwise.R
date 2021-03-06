
chunkwise <- function(x, nrows=1e4L){
  columns <- 1:LaF::ncol(x)
  .completed <- FALSE
  .chunk <- NULL
  reset <- function(){
  nrows <- nrows

    LaF::begin(x)
    .completed <<- FALSE
  }

  first_chunk <- function(cmds=NULL, .warn=FALSE){
    if (isTRUE(.warn)){
      warning("'group_by' and 'summarize' on a chunkwise textfile work per chunk!", call. = FALSE)
    }
    reset()
    next_chunk(cmds)
  }

  raw_chunk <- function(nrows){
    ch <- LaF::next_block(x, columns=columns, nrows=nrows)
    .completed <<- (nrow(ch) == 0)
    ch
  }

  next_chunk <- function(cmds=NULL){
    res <- NULL
    while(NROW(res) == 0){
      ch <- raw_chunk(nrows)
      if (is_complete()){
        return()
      }
      res <- play(ch, cmds)
    }
    res
  }

  is_complete <- function(){
    .completed
  }

  reset()

  structure(
    list( reset       = reset
        , next_chunk  = next_chunk
        , first_chunk = first_chunk
        , is_complete = is_complete
        , cmds        = list()
        , play        = play
        , src         = paste0("text file '", x@filename,"'")
        , .vars       = NULL
        ),
    class = c("chunkwise", "tbl")
  )
}

record <- function(.data, cmd){
  .data$cmds <- c(.data$cmds, list(cmd))
  .data$.vars <- NULL
  .data$.groups <- NULL
  .data
}

play <- function(.data, cmds=NULL){
#  browser()
  for (cmd in cmds){
    env <- parent.frame()
    expr <- cmd
    if (rlang::is_quosure(cmd)){
      env <- rlang::get_env(cmd)
      expr <- rlang::get_expr(cmd)
    }
    .data <- eval(expr, list(.data=.data), enclos = env)
  }
  .data
}

#' @export
as.data.frame.chunkwise <- function(x, row.names = NULL, optional = FALSE, ...){
  as.data.frame(collect(x), row.names = row.names, optional=optional, ...)
}
