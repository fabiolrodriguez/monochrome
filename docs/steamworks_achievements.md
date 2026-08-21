# Steamworks achievements

The internal achievement system is platform-independent. `PlatformAchievements`
detects the optional `Steam` engine singleton at runtime, waits for current user
stats, mirrors every locally unlocked achievement with `setAchievement`, and
commits the batch with `storeStats`.

The game remains fully functional when GodotSteam is not installed. Local save
data is the source of truth, so achievements missed while offline are retried on
the next session where Steam is available.

## Steamworks App Admin API Names

These identifiers are immutable. Create and publish achievements with the exact
API Names below before testing a Steam build:

| Internal ID | Steam API Name |
| --- | --- |
| `first_victory` | `ACH_FIRST_VICTORY` |
| `hunter_1` | `ACH_VOID_HUNTER_1` |
| `hunter_2` | `ACH_VOID_HUNTER_2` |
| `route_1` | `ACH_PATHFINDER` |
| `route_2` | `ACH_MONOCHROME` |
| `boss_scholar` | `ACH_SCHOLAR_OF_RUIN` |
| `tree_1` | `ACH_FIRST_BRANCHES` |
| `tree_2` | `ACH_DEEP_ROOTS` |

## Enabling Steam

1. Install a Godot 4.7-compatible Steamworks integration exposing the `Steam`
   engine singleton (GodotSteam is the expected adapter).
2. Configure the final App ID. The platform service calls GodotSteam's
   `steamInitEx` when present before requesting stats.
3. Define and publish all API Names above in Steamworks App Admin.
4. Launch the build through the Steam client and inspect
   `%steam_install%/logs/stats_log.txt` if an upload is rejected.

Do not rename an API Name in an existing `.tres` after publishing it. New
achievements only require a new `AchievementData` entry with a unique internal
ID and Steam API Name.

Reference: [Steamworks Stats and Achievements](https://partner.steamgames.com/doc/features/achievements)
and [ISteamUserStats](https://partner.steamgames.com/doc/api/ISteamUserStats).
