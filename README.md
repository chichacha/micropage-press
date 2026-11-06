# Micropage Press 🏭

**Design in HTML. Style with CSS. Capture with R.**

A small creative publishing experiment for turning HTML and CSS compositions into reusable PNG images.

Micropage Press explores a simple idea:

> What if the same web technologies we use to build interactive pages could also generate beautiful, consistent visual assets?

Instead of manually designing thumbnails in an image editor, we can create them with code, render them in a browser, and capture the results automatically.

## ✨ What I'm exploring

- **HTML + CSS** — Design flexible visual compositions using familiar web technologies.
- **R + webshot2** — Capture browser-rendered designs as PNG images.
- **Reusable templates** — Separate content, artwork, and styling.
- **Multiple formats** — Generate different image sizes from the same design.
- **Automation** — Eventually generate assets through repeatable publishing workflows.

## 📐 Target formats

| Format | Dimensions | Intended use |
|---|---|---|
| Social card | 1200 × 630 | Article previews, GitHub, social sharing |
| Wide banner | 1600 × 400 | Confluence and editorial headers |
| Presentation | 1600 × 900 | Slides and visual storytelling |
| Square card | 1080 × 1080 | Character cards and image galleries |

## 🧪 First experiment

**Can a simple HTML/CSS composition become a reproducible PNG image?**

Start small:

1. Create an HTML thumbnail with an illustration, title, and gradient.
2. Style it using CSS.
3. Capture it with `webshot2` in R.
4. Export the same composition at different dimensions.
5. Observe what works, what breaks, and what needs to adapt.

The first milestone isn't a complete publishing system. It's one successful, repeatable screenshot.

## 🛠️ Tools

- **HTML / CSS** — Layout, typography, gradients, and artwork.
- **R** — Scripting and automation.
- **webshot2** — Browser screenshots using Chromium.
- **Positron** — Development environment.
- **Git / GitHub** — Version control and experimentation.

### A first screenshot

Once `webshot2` is installed and `thumbnail.html` exists:

```r
install.packages("webshot2")

webshot2::webshot(
  url = "thumbnail.html",
  file = "thumbnail.png",
  vwidth = 1200,
  vheight = 630,
  cliprect = "viewport"
)
```

## 📁 Project structure

An initial structure to experiment with:

```text
micropage-press/
├── README.md
├── thumbnail.html
├── thumbnail.css
├── render.R
├── assets/
└── dist/
```

The structure will evolve as the experiments develop.

## 🌱 Where this might go

Micropage Press could eventually support visual assets for two personal projects:

**DERAILED** — Interactive editorial stories, data experiments, and curious explorations.

**Gomasu** — Pentomino characters, puzzles, and playful storytelling.

Potential future experiments include data-driven thumbnail generation, responsive compositions, SVG rendering, reusable themes, and automated publishing through GitHub Actions.

## 💡 Philosophy

**Make something small. Learn how it works. Make it reusable.**

This project is as much about learning web technologies and creative automation as it is about producing images.

The process of experimenting, debugging, designing, and discovering is part of the reward.

---

*An experiment in making the web printable, one micropage at a time.*