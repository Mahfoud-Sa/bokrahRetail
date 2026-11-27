# Reset Bokrah Retail Release Version Track to 1.x

Following the pivot from the legacy restaurant application to Bokrah Retail (ADR-0004), repository git tags still contained legacy `v3.5.x` releases. Because `AppUpdateRepositoryImpl` selects the highest semantic version among non-draft, non-prerelease GitHub Releases (ADR-0001), shipping a `v1.0.x` retail release alongside live `v3.5.x` releases would cause clients to treat `v3.5.7` as a newer update.

We decided to reset the Bokrah Retail distribution track to `v1.x` (starting with `v1.0.3`) and mark legacy `v3.5.x` GitHub Releases as prereleases rather than continuing from `v3.6.0`. This keeps retail product versioning aligned with the new codebase lifecycle while ensuring `AppUpdateRepositoryImpl` resolves `v1.x` releases as the latest App Update target.
