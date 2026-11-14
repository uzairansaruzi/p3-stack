---
name: ketchup-video
description: "Catch the user up like /ketchup, with a short subtitled video of slides for what happened and the waiting calls as text under it. Use for /ketchup-video."
disable-model-invocation: true
---

# Ketchup video

Follow [`/ketchup`](../ketchup/SKILL.md), but show what happened in a short subtitled video instead of its summary and visuals. Its window starts at the last message the user wrote before `/ketchup-video`, not before any earlier `/ketchup`. Writing the slide page and recording the video, outside the repo, is the one exception to its read-only rule. The reply is ketchup's opening sentence, the embedded video, one line naming any work left that you can do yourself, and the action items. When the video shows a call's options, call each option by the name the video gives it. If the recording fails, say so in one line and give only the calls.

## Slides

Use the screenshots (`preview_snapshot` with `save=true`), recordings, diffs, and data the work produced, not the chat's prose about them. Before you draw, write the one sentence the user should leave with and one line per slide. Drop each slide that does not change what the user knows. Use at most 10 slides, and fewer is better. Neither note goes in the reply.

Each slide makes one point. Build the slides on one picture and change it from slide to slide, rather than cut to an unrelated one. A color or shape means the same thing on every slide. Show the work in pictures, such as how a system works, a PR stack with each PR's state, a before and after of a fix, or options side by side. Point at what changed with arrows, highlights, and motion. A slide is never a bullet list, a status list, a table, or boxes with nothing connecting them.

Keep text to the minimum. Put each label on the thing it names, in plain words a person would say, not tags like "Tests: pass". Never caption what a picture shows, and never give a fact twice, across slides or in the text under them.

Show what came of each thing the user asked for, and whether it is done, still running, failed, or not checked. Never show something done that still waits on the user. Show any bug found and fixed on the way. If a visible change has no screenshot, say so on its slide and name what changed on screen. Draw only from facts you have. Never invent a number, and never draw a screen you did not capture.

## Subtitles

Give each slide one short subtitle line, about ten words, that says its point the way you would tell the user, from only what that slide shows. Say what the picture means rather than read out its labels. Put the subtitle in a strip below the slide, in the page itself, the same height on every slide and empty except for the subtitle, so it never covers the slide. Set it small, but readable when the video plays at chat size.

## Render

The video is a recording of one self-contained HTML slide page. T3 has no video encoder, and none is needed.

Build the page in a new temp directory outside the repo. Each slide is a full-width layer in a stage above a fixed-height subtitle strip. Draw pictures as inline SVG or HTML; embed captured screenshots as local images, which the static server below serves. Crossfade or slide between slides in CSS, about half a second. Use a 16:9 stage. The page stays blank until `window.startDeck()` runs, then plays every slide on its own timer, each for its hold, and sets `window.__deckDone = true` after the last hold. The last slide stays on screen.

Set each hold in the page's own timeline: at least one second for each three words the slide adds, never less than two seconds. The hold is the time a slide is fully on screen, not counting the motion into or out of it. A slide adds its subtitle and each word that was not on the slide before it, including a label it changes. The first slide adds all its words. Words inside a screenshot do not count.

Serve and record:

1. Serve the temp directory on loopback: `python3 -m http.server <port> --bind 127.0.0.1` in the background.
2. `preview_open` with `target: {"kind":"environment-port","port":<port>,"path":"/deck.html"}`, `reuseExistingTab: false`, `open: false`. Keep the `tabId`.
3. `preview_resize` with `mode: "freeform"`, `width: 1280`, `height: 720`.
4. Check every slide before recording. Make each one visible, `preview_snapshot` it, and check at chat size that its subtitle is readable and covers nothing. Fix the page and check again. Then reload the page, so the deck is blank again.
5. `preview_recording_start`, then at once `preview_evaluate` with `window.startDeck()`. Recording length includes your own call latency, so the clip has a short idle lead-in and tail on the blank page and the last slide. Make no calls between these two.
6. `preview_evaluate` with `awaitPromise: true` on a promise that polls `window.__deckDone` every 200 ms and resolves when it is true.
7. `preview_recording_stop`. It returns the video's local path (mp4, at most 50 MiB). Check that the file exists and is not empty.
8. `t3_preview_close` the tab, stop the static server, and leave the temp directory outside the repo.

Embed the video in the reply with Markdown image syntax and the absolute path. If it exceeds 50 MiB, or the recording call fails, shorten the deck and record again once, then fall back to the calls alone. There is no probe for the file's frames, so the hold check is by construction: the page timeline sets every hold, and the per-slide snapshots in step 4 cover legibility. Count the words each slide adds against its hold before step 5, and fix any slide you cannot read in that time.
