# philiplambok.github.io

Personal blog, built with [Jekyll](https://jekyllrb.com).

## Stack

| Dependency | Version | Defined in |
|---|---|---|
| [Ruby](https://www.ruby-lang.org) | 4.0.7 | `mise.toml` |
| [Jekyll](https://jekyllrb.com) | 4.4 | `Gemfile` |
| [Minima](https://github.com/jekyll/minima) (dark skin) | 3.0 dev, pinned to commit `4de3223` | `Gemfile`, `_config.yml` |
| [jekyll-feed](https://github.com/jekyll/jekyll-feed) | 0.18 | `Gemfile` |
| [jekyll-seo-tag](https://github.com/jekyll/jekyll-seo-tag) | 2.9 | `Gemfile` |

Exact versions of every gem are locked in `Gemfile.lock`. Minima is installed from
GitHub because the dark skin is not in any released version yet.

The site is deployed to GitHub Pages by `.github/workflows/pages.yml` on every push to `main`.

## Setup

Requires [mise](https://mise.jdx.dev).

```sh
mise install      # installs Ruby
mise run serve    # installs gems, serves at http://localhost:4000
mise run build    # builds into _site
```

## Writing a post

```sh
mise run new "My post title"
```

This creates `_posts/YYYY-MM-DD-my-post-title.md` with the front matter filled in
(layout, title, date). Write the content below the front matter, then preview it
with `mise run serve`.

## Archive

Articles written between 2019 and 2023 are no longer published on the site.
They are kept in [`archive/posts`](archive/posts) and can be read directly on GitHub.
