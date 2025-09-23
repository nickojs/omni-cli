# Changelog

## [0.0.6] - 2025-09-22

### Security Patches
- **Fixed command injection vulnerability** in build script (commit f12d1c9, 87aa881)
  - Replaced dangerous `eval` usage with safe parsing
  - Added input validation for PKGBUILD variables
  - Added directory structure validation for file operations
  - Enhanced privilege escalation protections for package installation
- **Improved build process security**
  - Auto-update checksums to prevent validation failures
  - Added file existence verification before sudo operations

### Added
- Navigator module for filesystem browsing
- Killall menu entry for project management
- JSON backup functionality with `--bkpJson` flag

### Fixed
- Tmux panel propagation issues
- Build script checksum validation breaking normal builds

### Changed
- Enhanced PKGBUILD security compliance per 2025 Arch guidelines