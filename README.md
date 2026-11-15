# GroupFilter-Forever

A World of Warcraft: Forever addon for filtering **solo players** in the Group
Finder's Browse tab by their listed role and class.

**Version:** 1.1.0  
**Game:** World of Warcraft: Forever 1.60.1

## Install

1. Copy the `GroupFilter-Forever` folder to
   `World of Warcraft\_forever_\Interface\AddOns\GroupFilter-Forever`.
   The `.toc` file must be directly inside that folder.
2. Enable **GroupFilter-Forever** in the character selection AddOns list.
3. Restart the game or enter `/reload` in chat.

## How to use

1. Open **Group Finder > Browse**, choose an activity using Blizzard's filters,
   and refresh the search. The addon panel appears to the right.
2. Select a role and/or class to narrow the results. A player who lists multiple
   roles matches any of those roles.
3. Use **Hide classes...** to exclude classes. Exclusions combine with both
   dropdowns and reset when you reload or exit the game.
4. Click **Invite** next to a player, or use **Previous** and **Next** to browse
   more results. The invite button is disabled when Group Finder does not offer
   an invite action.

Each row shows the player name, level, location, and class and roles. Text uses
class colors when available. `Lv ?` means the level is unavailable or
restricted; `Unknown` means the client did not provide an accessible location.

## How it works

The addon filters the current Group Finder search results for solo listings. It
updates the panel when search results or group membership change. It does not
search chat, the Who list, or players who have not listed themselves, and it
cannot recover results the server has not returned. Group listings remain in
Blizzard's original list.

Listings without the selected role or class information do not match that
filter. Listings with an unknown class remain visible when no specific class is
selected. Client restrictions can prevent the addon from reading some listing
data; the panel warns when detected.

## Commands

GroupFilter-Forever has **no addon-specific slash commands**. Use its panel
controls to filter and invite players. These built-in WoW commands can help:

| Command | Purpose |
| --- | --- |
| `/reload` | Reload the interface and addons after installation or changes. |
| `/console scriptErrors 1` | Enable Lua error messages for troubleshooting. |

## Troubleshooting

- **Panel missing:** Confirm the folder and `.toc` are in the correct AddOns
  directory, the addon is enabled, and Group Finder's Browse tab is open.
  Reload the interface after changes.
- **No results:** Run a Group Finder search and check the role, class, and
  hidden-class filters. The addon only shows matching solo listings.
- **Search failed:** Use Blizzard's Refresh button and try again.
- **Unknown location or level:** The client may not provide that information
  for the listing.
- **Lua error:** Enable script errors using the command above and record the
  error message.

## License

Personal gameplay use is permitted. Modification and redistribution require
permission. See [LICENSE](LICENSE).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for recent changes.
