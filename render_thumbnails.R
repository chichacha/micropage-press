# Micropage Press — HTML/CSS -> PNG thumbnail generator
# =====================================================
#
# PURPOSE
#   For each micropage defined in pages.json, fill an HTML template with
#   page-specific content, save an HTML file, and optionally photograph it
#   as a PNG using webshot2 (a headless Chromium browser).
#
# FIRST-TIME SETUP (run once in the R console)
#   install.packages(c("jsonlite", "webshot2"))
#
# RUN FROM POSITRON (with this folder as your working directory)
#   source("render_thumbnails_annotated.R")
#
# RUN FROM A TERMINAL (from any directory)
#   Rscript /path/to/render_thumbnails_annotated.R
#   Rscript /path/to/render_thumbnails_annotated.R find-the-monkey
#
# With no page slug, all entries in pages.json are rendered.
# With one or more slugs, only those pages are rendered.


# 1. Find the project folder -----------------------------------------------
#
# commandArgs() returns the arguments supplied when this R session started.
# trailingOnly = FALSE includes R's own startup arguments, such as:
#   "--file=/path/to/render_thumbnails_annotated.R"
# when you launch the script using Rscript.
cmd <- commandArgs(trailingOnly = FALSE)

# grep() searches text for a pattern.
# "^--file=" means "starts with --file=" (^ anchors the start).
# value = TRUE returns the matching text, rather than its positions.
script_arg <- grep("^--file=", cmd, value = TRUE)

if (length(script_arg) > 0) {
  # sub() replaces just the FIRST match of a pattern in a string.
  # Remove "--file=" so only the path to the script remains.
  script_path <- sub("^--file=", "", script_arg[1])

  # normalizePath() turns a relative path into an absolute path.
  # mustWork = TRUE gives a helpful error if the file doesn't exist.
  script_path <- normalizePath(script_path, mustWork = TRUE)

  # dirname() returns the parent directory containing the script.
  root <- dirname(script_path)
} else {
  # When using source() inside Positron, --file= generally isn't present.
  # Fall back to the CURRENT WORKING DIRECTORY (check with getwd()).
  # Important: open the project folder or setwd() before sourcing.
  root <- getwd()
}

message("Project folder: ", root)


# 2. Check required packages -----------------------------------------------
#
# requireNamespace() checks whether a package is INSTALLED without attaching
# it with library(). quietly = TRUE suppresses the usual status messages.
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop('Missing package: install.packages("jsonlite")')
}

# webshot2 is optional: we can still generate HTML if it is not installed.
capture_available <- requireNamespace("webshot2", quietly = TRUE)
if (!capture_available) {
  message('PNG export skipped: install.packages("webshot2") to enable screenshots.')
}


# 3. Define image sizes -----------------------------------------------------
#
# A named list lets each output format have a name and named dimensions.
# c() combines values into a vector; 1200L means an integer (not a decimal).
formats <- list(
  social = c(width = 1200L, height = 630L),       # Jira / social / link preview
  confluence = c(width = 1600L, height = 400L)   # wide, shallow banner
)


# 4. Define a small helper function -----------------------------------------
#
# HTML treats certain characters specially. For example, < is interpreted
# as the start of a tag, so a title like "R < Python?" needs escaping.
# Each gsub() replaces ALL occurrences of the specified character.
# fixed = TRUE means "match these exact characters", not a regex.
# Order matters: escape & first so we don't re-escape inserted entities.
escape_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}


# 5. Read the page configurations ------------------------------------------
#
# file.path() builds file paths with the right separator for your OS.
# fromJSON() reads JSON into R. simplifyVector = FALSE keeps nested JSON
# objects as lists; page$image will then retrieve a value by key.
pages_file <- file.path(root, "pages.json")
pages <- jsonlite::fromJSON(pages_file, simplifyVector = FALSE)

# trailingOnly = TRUE returns only arguments AFTER the script name.
# Example: Rscript render_thumbnails_annotated.R find-the-monkey
#          -> args is "find-the-monkey"
# In Positron's interactive session, this is usually character(0).
args <- commandArgs(trailingOnly = TRUE)

# If a slug was supplied, render only the requested page(s).
# Otherwise, names(pages) gets every top-level key in pages.json.
slugs <- if (length(args) > 0) args else names(pages)

# setdiff(A, B) returns elements in A that are missing from B.
# This catches typos such as "find-monky" before we start rendering.
missing_slugs <- setdiff(slugs, names(pages))
if (length(missing_slugs) > 0) {
  stop("Unknown page: ", paste(missing_slugs, collapse = ", "))
}


# 6. Read the template and prepare the output folder -----------------------
#
# readLines() reads the HTML file as a character vector, one line per entry.
# warn = FALSE avoids warnings about a missing newline on the last line.
template <- readLines(
  file.path(root, "thumbnail.html"),
  warn = FALSE,
  encoding = "UTF-8"
)

# dir.create() creates the output folder, but won't complain if it exists.
# recursive = TRUE also creates any missing parent folders.
out_dir <- file.path(root, "dist")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)


# 7. Render every selected page, in every format ---------------------------
#
# Outer loop: each page slug, e.g. "find-the-monkey".
for (slug in slugs) {
  # [[slug]] retrieves one named element from a list.
  page <- pages[[slug]]

  # Fail early if the illustration referenced by pages.json is missing.
  # stopifnot() ends the script if its condition is FALSE.
  stopifnot(file.exists(file.path(root, page$image)))

  # Inner loop: every format name, e.g. "social" and "confluence".
  for (variant in names(formats)) {
    # Retrieve a named vector such as c(width = 1200L, height = 630L).
    size <- formats[[variant]]

    # These values will replace placeholders inside thumbnail.html.
    # Example: {{SUBTITLE}} becomes page$subtitle.
    # The names on the LEFT must match the placeholder names in HTML.
    values <- list(
      PAGE_TITLE = paste(page$title_first, page$title_second),
      VARIANT_LABEL = variant,
      VARIANT = variant,
      WIDTH = as.character(size[["width"]]),
      HEIGHT = as.character(size[["height"]]),
      IMAGE = page$image,
      IMAGE_POSITION = page$image_position,

      # Use an optional separate crop position for wide banners.
      # If missing, reuse the normal position.
      IMAGE_POSITION_WIDE = if (!is.null(page$image_position_wide)) {
        page$image_position_wide
      } else {
        page$image_position
      },

      # Fallback alt text when pages.json has no image_alt.
      IMAGE_ALT = if (!is.null(page$image_alt)) {
        page$image_alt
      } else {
        paste(page$title_first, page$title_second)
      },

      EYEBROW = page$eyebrow,
      TITLE_FIRST = page$title_first,
      TITLE_SECOND = page$title_second,
      SUBTITLE = page$subtitle,
      DESCRIPTION = page$description,
      FOOTER = page$footer
    )

    # Start with the unchanged template for every page and variant.
    page_html <- template

    # Replace placeholders, one named field at a time.
    # paste0() joins strings WITHOUT a separator.
    # Example: paste0("{{", "SUBTITLE", "}}") -> "{{SUBTITLE}}"
    for (key in names(values)) {
      placeholder <- paste0("{{", key, "}}")
      replacement <- escape_html(values[[key]])
      page_html <- gsub(placeholder, replacement, page_html, fixed = TRUE)
    }

    # Build output names such as dist/find-the-monkey-social.html/.png.
    html_file <- file.path(out_dir, paste0(slug, "-", variant, ".html"))
    png_file <- file.path(out_dir, paste0(slug, "-", variant, ".png"))

    # Write the rendered HTML. useBytes = TRUE avoids re-encoding its text.
    writeLines(page_html, html_file, useBytes = TRUE)
    message("HTML: ", html_file)

    # If webshot2 is installed, photograph the browser-rendered HTML.
    if (capture_available) {
      # Browsers use file:// URLs rather than regular OS file paths.
      # normalizePath(..., winslash = "/") ensures forward slashes.
      # URLencode() escapes spaces and special path characters for a URL.
      html_path <- normalizePath(html_file, winslash = "/", mustWork = TRUE)
      uri <- paste0("file://", utils::URLencode(html_path, reserved = FALSE))

      webshot2::webshot(
        url = uri,                         # Local HTML page to open
        file = png_file,                   # Destination screenshot
        vwidth = unname(size[["width"]]), # Browser viewport width in px
        vheight = unname(size[["height"]]),# Browser viewport height in px
        selector = "#thumbnail",           # Capture element with id="thumbnail"
        zoom = 1,                          # Normal browser zoom
        delay = 0.4                        # Brief pause before screenshot (seconds)
      )
      message("PNG:  ", png_file)
    }
  }
}

message("Done. Use the PNGs in Posit Connect, Confluence, or Jira.")

# NOTE ON RELATIVE ASSETS:
# HTML files are written into dist/, not the project root. If thumbnail.html
# references CSS or images with relative URLs, check that the paths still
# resolve from dist/ (e.g. ../thumbnail.css or ../assets/illustration.png).
# A PNG can be created while silently showing missing images, so inspect it!
