# NoRuski

A lightweight World of Warcraft addon that automatically declines **pending Premade
Group Finder (LFG) applications** from players whose character names are written in
the **Cyrillic alphabet** — but only while *you* are the host/leader of the listing.

This is a language/communication convenience filter for group leaders who run
coordinated content and want applicants they can reliably communicate with. It only
ever acts on your own LFG listing and never touches anyone else's groups.

> Verified against the **World of Warcraft: Midnight (12.0.5)** client API.

## What it does

- Watches your active Premade Group Finder listing for new applicants.
- For every **pending** application (`status == "applied"`, not already invited/declined),
  it inspects each applicant member's name.
- If any member's name contains a Cyrillic character, the application is declined via
  `C_LFGList.DeclineApplicant`.
- It only runs when you have an active listing and, if grouped, are the group leader.

It does **not** touch party, raid, guild, or whisper invites — strictly LFG applicants.

## Installation

1. Download/clone this repository.
2. Copy the folder into your AddOns directory and make sure it is named `NoRuski`:
   ```
   World of Warcraft\_retail_\Interface\AddOns\NoRuski\
     NoRuski.toc
     NoRuski.lua
   ```
3. Restart the client or `/reload`. Enable **NoRuski** on the character select AddOns list.

## Usage

The addon works automatically once enabled. Slash commands:

| Command | Description |
| --- | --- |
| `/noruski on` \| `off` | Enable or disable auto-declining |
| `/noruski scan` | Re-check the current LFG applicants now |
| `/noruski announce` | Toggle chat announcements when an applicant is declined |
| `/noruski test <name>` | Check whether a given name is detected as Cyrillic |

`/nr` is a shorthand alias for `/noruski`.

## How name detection works

Names arrive as UTF-8. The addon decodes each codepoint and flags the name if any
character falls in a Cyrillic Unicode block:

- Cyrillic (U+0400–U+04FF)
- Cyrillic Supplement (U+0500–U+052F)
- Cyrillic Extended-A (U+2DE0–U+2DFF)
- Cyrillic Extended-B (U+A640–U+A69F)
- Cyrillic Extended-C (U+1C80–U+1C8F)

Latin names (including accented characters like `Ñ`, `Æ`) and other scripts (CJK, etc.)
are not affected.

> Note: this is a **script-based** filter. It identifies the alphabet a name is written
> in, not a player's actual nationality.

## Settings

Settings persist per account in `NoRuskiDB`:

- `enabled` – master toggle (default `true`)
- `announce` – print a chat line when an application is declined (default `true`)

## License

MIT
