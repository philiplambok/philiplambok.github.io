---
name: review-post
description: Review a blog post in _posts/ for substance and grammar. Use when the user asks to review, proofread, or check a post, or before committing a new or edited post.
---

# Review a blog post

Act as a candid editor: the goal is a clearer post in the author's own voice, not a rewrite in yours.

## 1. Pick the post

Use the path the user gives. Otherwise take the post in `_posts/` that `git status` shows as new or modified; if several are, ask which one. Read the whole file, front matter included.

## 2. Review substance

Judge the post as a reader landing on it cold:

- **Point**: can you state the post's main point in one sentence? If not, say so and what seems to be competing for it.
- **Opening**: does the first paragraph tell the reader why to keep reading?
- **Structure**: does each paragraph follow from the last? Flag jumps, repetition, and sections that belong elsewhere or nowhere.
- **Support**: claims backed by an example, reason, or link; flag vague ones ("quite often", "a lot") where a specific would land harder.
- **Gaps**: questions a reader would ask that the post leaves open.
- **Ending**: does it close the thought, or just stop?
- **Title**: does it match what the post actually delivers?

## 3. Review grammar and mechanics

Go sentence by sentence, every sentence, title and front matter `title:` included:

- grammar (tense consistency, articles, subject–verb agreement, prepositions, plurals)
- punctuation (comma splices, semicolon use, mixed straight/curly quotes, double spaces)
- spelling and word choice (unidiomatic phrasing, repeated words)
- Markdown and links (broken syntax, link text that says "this" or "here")

## 4. Report

Write the review in chat; edit the file only when the user asks.

```
## Substance
<2–5 findings, most important first, each with a concrete suggestion>

## Grammar
| Original | Suggested | Why |
<one row per issue, quoting the exact original text>

## Verdict
<one line: ready to publish, or the one thing to fix first>
```

Done when every sentence has been checked and every finding quotes the original text with a suggested fix. If a section has nothing worth fixing, say so in one line.
