---
name: dictation-vocabulary
description: Use when a term in the user's message looks like a speech-to-text mistranscription — you had to reinterpret it from context (e.g. "lum" meaning Loom) or the user corrects it ("quería decir X") — to teach the voxtype dictation setup the right spelling. Also when the user asks to undo or list what voxtype has learned.
compatibility: Requires voxtype with ~/.config/voxtype/config.toml and Python 3.11+. Linux (systemd) or macOS (launchd). Syncs the chezmoi source when config.toml is managed.
---

# Dictation vocabulary

The user dictates most messages with voxtype (Groq Whisper, then an LLM
normalizer). Each mistranscription you catch is recorded so the next dictation
gets it right. Record it **without asking**, then tell the user. This is a side
effect: finish it in one step and carry on with the user's actual request.

Script: `scripts/voxtype-vocab` next to this file (also on PATH as
`voxtype-vocab`).

## 1. Decide whether to record

Record only when one of these holds:

- The user corrected the term ("es Loom, no lum", "quería decir X").
- Context makes the intended term unambiguous, and it is a proper noun,
  product, tool, project, person or technical term that dictation mangled.

Skip it when you are choosing between several plausible terms, when the
odd word is correct in context, or when it looks like a keyboard typo rather
than a phonetic error.

Completion criterion: you have TERM, spelled exactly as its owner writes it
(Loom, OpenRouter, GitHub), and each HEARD form exactly as it appeared in
the message.

## 2. Choose replacement or vocabulary only

A replacement is a blind, case-insensitive substitution applied to every
future dictation. Pass `--no-replace` when a HEARD form is a real Spanish or
English word or could be meant literally (e.g. "bag" for bug, "cloud" for
Claude). Vocabulary alone still steers Whisper and the LLM normalizer.

## 3. Run it

```bash
voxtype-vocab add "Loom" --heard "lum"
voxtype-vocab add "Claude" --heard "cloud" --no-replace
```

It adds TERM to `~/.config/voxtype/vocabulary.txt`, sets the replacement,
regenerates the Whisper `initial_prompt`, restarts voxtype once it is idle and
re-adds the files to chezmoi when chezmoi manages them. It never commits. It
refuses a TERM that is already registered as a wrong form.

Completion criterion: exit code 0 and an "Añadido a voxtype" or
"Sin cambios" line.

## 4. Tell the user

Add one line to your reply in the user's language, e.g.:

> Diccionario de voxtype: «lum» → Loom. Para deshacer: `voxtype-vocab undo`

If the script failed (voxtype missing on this machine, config error), say so
in one line and continue. Never edit `config.toml` by hand, and never use
`voxtype config unset text.replacements.<x>`: it wipes every replacement.

## Undo and inspect

- `voxtype-vocab undo` reverts the latest addition; repeat to go further back.
- `voxtype-vocab list` shows context, vocabulary, replacements and recent additions.
- `voxtype-vocab restart` restarts voxtype if a change could not be applied
  because it was busy.

Run these when the user asks to undo, remove or review what was learned.
