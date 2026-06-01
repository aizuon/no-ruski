# NoRuski — CurseForge description

NoRuski automatically declines **pending Premade Group Finder (LFG) applications** from
players whose character names are written in the **Cyrillic alphabet**, but only while
you are the host/leader of the listing.

It is a language/communication convenience filter for group leaders. It only ever acts
on your own LFG listing — it never touches party, raid, guild, or whisper invites, and
it never affects groups you don't lead.

[b]Features[/b]
[list]
[*]Automatically declines pending LFG applicants with Cyrillic names
[*]Only runs while you host an active listing (and are group leader)
[*]Inspects every member of an application, not just the leader
[*]Optional chat announcements when an applicant is declined
[*]Tiny, no dependencies, no background CPU use
[/list]

[b]Slash commands[/b]
[list]
[*][b]/noruski on | off[/b] — enable or disable auto-declining
[*][b]/noruski scan[/b] — re-check current applicants now
[*][b]/noruski announce[/b] — toggle chat announcements
[*][b]/noruski test <name>[/b] — check if a name is detected as Cyrillic
[/list]

[b]Notes[/b]
This is a script-based filter: it detects the alphabet a name is written in, not a
player's nationality. Latin (including accented characters) and other scripts are not
affected.

Source code: https://github.com/aizuon/no-ruski
Verified against World of Warcraft: Midnight (12.0.5).
