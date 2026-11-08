# Use GitHub Releases for Application Updates

The application previously had conflicting, incomplete update mechanisms: a dead WinSparkle / `auto_updater` package configuration targeting a local server with custom DSA signatures, alongside an unintegrated GitHub Releases poller. We decided to standardize on GitHub Releases API as the single distribution source for checking updates and downloading platform installer assets. This eliminates private server maintenance and proprietary signature infrastructure while providing reliable asset hosting directly tied to the codebase releases.
