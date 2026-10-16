---
name: review-post
description: Review a blog post in _posts/ for substance and grammar. Use when the user asks to review, proofread, or check a post, or before committing a new or edited post.
---

# Review a blog post

Act as a candid editor: the goal is a clearer post in the author's own voice, not a rewrite in yours.

## 1. Pick the post

Use the path the user gives. Otherwise find the post being worked on from git, not from the folder listing:

1. Run `git status --short -- _posts/` and `git diff HEAD -- _posts/` to see new, modified, and staged posts.
2. If nothing shows, check `git log origin/main..HEAD --name-only -- _posts/` for posts in commits not yet pushed.
3. If exactly one post turns up, review it. If several do, ask which one. If none do, say so and ask for a path; do not fall back to the newest or only post in `_posts/`, because that post is old work.

Read the whole file, front matter included. For a modified post (not new), focus the findings on the changed lines from the diff and read the rest only for context, unless the user asks for a full review.

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

Write a short summary in chat first:

```
## Verdict
<one line: ready to publish, or the one thing to fix first>

<count of substance and grammar findings; for each section with nothing worth fixing, say so in one line>
```

## 5. Ask about each suggestion

Put every finding to the user with the AskUserQuestion tool, one question per finding. Ask substance findings first, most important first, then grammar findings in the order they appear in the post. One call holds at most 4 questions, so send them in batches of 4 until all are asked.

For each question:

- `question`: the finding and why it matters, quoting the exact original text.
- `header`: a short tag such as `Ending` or `Grammar`.
- options (2–4):
  - `Apply` (put it first): the suggested fix, with a `preview` showing the original and suggested text.
  - `Keep original`: leave the text as it is.
  - For substance findings that need your input (e.g. a missing reason only you know), offer up to two alternative wordings as extra options; the user can also pick "Other" to write their own.

After all answers are in, edit the post with the accepted fixes and any text the user wrote under "Other", then list in chat which findings were applied and which were kept.

Done when every sentence has been checked, every finding has been asked with the exact original text quoted, and every accepted fix is applied to the file.
