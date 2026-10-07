#' Parse or Edit TOML text
#'
#' The [edit_toml()] function modifies values in a TOML text while retaining the
#' order, comments, and whitespace. Use `read_toml()` and `write_toml()` to convert
#' between TOML text and R lists.
#'
#' @references [toml-edit-js examples](https://github.com/rainbowatcher/toml-edit-js/blob/main/tests/edit.test.ts)
#' @export
#' @return `parse_toml()` returns a list and `edit_toml()` returns the modified
#' TOML text.
#' @name toml
#' @rdname toml
#' @param toml string with toml text
#' @param file path to file with toml text
#' @param as_json return output as json string instead of R list
read_toml <- function(file, as_json = FALSE){
  parse_toml(readLines(file), as_json = as_json)
}

#' @export
#' @rdname toml
parse_toml <- function(toml, as_json = FALSE){
  toml <- read_input(toml)
  ctx$assign('input', toml)
  output <- ctx$eval('JSON.stringify(toml_edit.parse(input))')
  if(as_json){
    return(output)
  }
  jsonlite::parse_json(output)
}

#' @export
#' @rdname toml
#' @param toml string
#' @param x vector or json string to convert to TOML
#' @param auto_unbox convert atomic vectors of length 1 as scalars in TOML, unless
#' they are wrapped in `I()`. See also [jsonlite::toJSON].
write_toml <- function(x, auto_unbox = TRUE){
  if(!is.character(x)){
    x <- jsonlite::toJSON(x, auto_unbox = TRUE, digits = NA)
  }
  ctx$assign('input', x)
  as_toml(ctx$eval('toml_edit.stringify(JSON.parse(input))'))
}

#' @export
#' @rdname toml
#' @param field name of field to change, for example `package.version`.
#' @param value new value of field to set.
#' @examples
#' toml <- readLines('https://raw.githubusercontent.com/posit-dev/air/refs/heads/main/Cargo.toml')
#' toml <- edit_toml(toml, 'workspace.package.rust-version', '1.84')
#' toml <- edit_toml(toml, 'workspace.dependencies.bla', list(path = "./yolo", rev = "123"))
edit_toml <- function(toml, field, value){
  toml <- read_input(toml)
  if(is.null(value)){
    value <- V8::JS("null")
  }
  stopifnot(is.character(field) && length(field) == 1)
  ctx$assign('input', toml)
  ctx$assign('field', field)
  ctx$assign('value', value)
  as_toml(ctx$eval('toml_edit.edit(input, field, value)'))
}

read_input <- function(toml){
  stopifnot(is.character(toml))
  paste(toml, collapse = '\n')
}

as_toml <- function(x){
  class(x) <- 'toml'
  x
}

#' @export
print.toml <- function (x, ...) {
  cat(x, "\n")
}
