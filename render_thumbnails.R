# Reusable HTML/CSS -> PNG thumbnail generator for micropages.
# Setup (once): install.packages(c("jsonlite", "webshot2"))
# In Positron: open this folder, then source("render_thumbnails.R")
# Terminal: Rscript render_thumbnails.R [optional-page-slug]

# Resolve paths from the script's folder when run with Rscript; otherwise
# expect Positron/R's working directory to be this folder.
cmd <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", cmd, value = TRUE)
root <- if (length(script_arg)) {
  dirname(normalizePath(sub("^--file=", "", script_arg[1]), mustWork = TRUE))
} else {
  getwd()
}

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop('Missing package. Run install.packages("jsonlite")')
}

# Add new output sizes here. Both use the same template and image.
formats <- list(
  social = c(width = 1200L, height = 630L),     # Posit Connect / Jira / Open Graph
  confluence = c(width = 1600L, height = 400L) # skinny-wide Confluence banner
)

escape_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

pages <- jsonlite::fromJSON(file.path(root, "pages.json"), simplifyVector = FALSE)
args <- commandArgs(trailingOnly = TRUE)
slugs <- if (length(args)) args else names(pages)
missing_slugs <- setdiff(slugs, names(pages))
if (length(missing_slugs)) stop("Unknown page: ", paste(missing_slugs, collapse = ", "))

template <- readLines(file.path(root, "thumbnail.html"), warn = FALSE, encoding = "UTF-8")
out_dir <- file.path(root, "dist")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

capture_available <- requireNamespace("webshot2", quietly = TRUE)
if (!capture_available) {
  message('PNG export skipped: run install.packages("webshot2") to enable screenshots.')
}

for (slug in slugs) {
  page <- pages[[slug]]
  stopifnot(file.exists(file.path(root, page$image)))
  for (variant in names(formats)) {
    size <- formats[[variant]]
    values <- list(
      PAGE_TITLE = paste(page$title_first, page$title_second),
      VARIANT_LABEL = variant,
      VARIANT = variant,
      WIDTH = as.character(size[["width"]]),
      HEIGHT = as.character(size[["height"]]),
      IMAGE = page$image,
      IMAGE_POSITION = page$image_position,
      IMAGE_POSITION_WIDE = if (!is.null(page$image_position_wide)) page$image_position_wide else page$image_position,
      IMAGE_ALT = if (!is.null(page$image_alt)) page$image_alt else paste(page$title_first, page$title_second),
      EYEBROW = page$eyebrow,
      TITLE_FIRST = page$title_first,
      TITLE_SECOND = page$title_second,
      SUBTITLE = page$subtitle,
      DESCRIPTION = page$description,
      FOOTER = page$footer
    )
    page_html <- template
    for (key in names(values)) {
      page_html <- gsub(paste0("{{", key, "}}"), escape_html(values[[key]]), page_html, fixed = TRUE)
    }
    html_file <- file.path(out_dir, paste0(slug, "-", variant, ".html"))
    png_file <- file.path(out_dir, paste0(slug, "-", variant, ".png"))
    writeLines(page_html, html_file, useBytes = TRUE)
    message("HTML: ", html_file)

    if (capture_available) {
      uri <- paste0("file://", utils::URLencode(normalizePath(html_file, winslash = "/", mustWork = TRUE), reserved = FALSE))
      webshot2::webshot(
        url = uri, file = png_file,
        vwidth = unname(size[["width"]]),
        vheight = unname(size[["height"]]),
        selector = "#thumbnail", zoom = 1, delay = 0.4
      )
      message("PNG:  ", png_file)
    }
  }
}
message("Done. Put a PNG in your Posit Connect, Confluence, or Jira thumbnail field.")
