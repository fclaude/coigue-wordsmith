# Wordsmith

Rhymes, synonyms and spelling suggestions for [Coigüe](https://github.com/fclaude/coigue), for the word under
the cursor. The words come from [Datamuse](https://www.datamuse.com/api/).

| Command | Shows |
| --- | --- |
| `:rhyme` | words that rhyme with it (near rhymes when there are no perfect ones) |
| `:synonym` | words that mean the same |
| `:spell` | words spelled like it |

Put the cursor on a word and type the command. The status line says it is looking; a moment later a list
opens. Type to narrow it, Up and Down to move, Enter to replace the word with the one chosen, Esc to leave
the text alone. The replacement keeps the word's capitals (`Tree` becomes `Free`, `TREE` becomes `FREE`).

You can keep typing while it looks. If the word is still where it was, it is replaced; if you edited the
word itself in the meantime, nothing is replaced and the status line says so.

## Install

This module needs Coigüe 0.5.0 or newer, which can give a module network access.

```
:module-add fclaude/coigue-wordsmith
```

Coigüe shows the code first, and the network the module asks for:

```
NETWORK: can reach api.datamuse.com (GET, HEAD)
It can read your text while its commands run, so it could send text to these hosts.
```

Read the code (it is one short file, `modules/wordsmith.scm`) and press `y`. Then add this to
`init.scm` and type `:reload`:

```scheme
(require wordsmith)
```

If another module has a command called `rhyme`, `synonym` or `spell`, Coigüe asks you to be specific; type
`:wordsmith/rhyme`.

## What it sends

Only the word under the cursor, in the address of an HTTPS request to `api.datamuse.com`, for example
`https://api.datamuse.com/words?max=30&rel_rhy=tree`. Datamuse sees that word and your IP address. Nothing
else is sent, and the module can reach no other host: Coigüe refuses any other address, any redirect to
one, and any request that is not a `GET`. The request runs in a background task, so the editor never waits
for it.

## What it can and cannot do

* Datamuse's `:spell` is a similarity search, not a spell-checker. It finds `definitely` for `definately`
  and misses some common slips (`receive` for `recieve`). Treat it as a nudge.
* It shows at most 30 words.
* The service is free for up to 100,000 requests a day without a key. This module uses no key.

## Licence

MIT. See `LICENSE`.
