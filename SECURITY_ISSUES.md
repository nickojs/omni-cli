# Security Issues Tracking

**Status**: In Progress
**Created**: 2025-09-22
**Last Updated**: 2025-09-22

> **Note**: This file tracks security vulnerabilities found in the fm-manager project. Delete this file once all issues are resolved.

## Summary
- **Critical**: 0 issues
- **High**: ~~1~~ 0 issues (1 resolved ✅)
- **Medium**: ~~3~~ 0 issues (3 resolved ✅)
- **Low**: 2 issues
- **Total**: 6 issues (4 resolved, 2 remaining)

---

## HIGH SEVERITY ISSUES

### ✅ H001: Command Injection via eval() - **RESOLVED**
- **File**: `build/rebuild-package.sh:6`
- **Code**: ~~`eval $(grep -E '^(pkgname|pkgver|pkgrel)=' PKGBUILD)`~~
- **Issue**: Uses eval to execute grep output without validation
- **Risk**: Arbitrary code execution if PKGBUILD is compromised
- **CVE**: Similar to CVE-2014-6271 (Shellshock)
- **Status**: ✅ **RESOLVED** (2025-09-22)
- **Fix Applied**:
  - Replaced eval with safe parsing using grep + cut + tr
  - Added input validation and sanitization
  - Added regex validation for package variables
  - Quoted all variable expansions in commands
- **Verification**: Tested with malicious PKGBUILD - script correctly rejects and exits

---

## MEDIUM SEVERITY ISSUES

### ✅ M001: Unquoted Variable Expansion - **NOT A REAL ISSUE**
- **Files**: Multiple locations reviewed
- **Issue**: Variables appeared to be used without quotes in commands
- **Risk**: Command injection via word splitting/glob expansion
- **CVE**: Related to CVE-2021-42740
- **Status**: ✅ **RESOLVED** (2025-09-22) - **False Positive**
- **Analysis**: Upon detailed review, all variables are properly quoted where security-critical:
  - Path concatenations like `"$PWD/$folder_name"` are properly quoted
  - Variables in echo statements are not security risks
  - Command substitutions are safe contexts
  - No genuine unquoted variable expansion vulnerabilities found

### ✅ M002: Privilege Escalation Risk - **RESOLVED**
- **File**: `build/rebuild-package.sh:30`
- **Code**: ~~`sudo pacman -U $pkgname-$pkgver-$pkgrel-any.pkg.tar.zst`~~
- **Issue**: sudo with variables from potentially untrusted PKGBUILD source
- **Risk**: Installation of arbitrary packages
- **Status**: ✅ **RESOLVED** (2025-09-22)
- **Fix Applied**:
  - Variables are now validated and sanitized (from H001 fix)
  - Added file existence verification before sudo
  - Added path traversal protection (prevents "../" and "/" in filename)
  - Use explicit path prefix "./" for clarity
  - Combined with H001 regex validation, prevents malicious package names
- **Verification**: Tested path traversal protection logic successfully

### ✅ M003: Unsafe File Operations - **RESOLVED**
- **Files**:
  - `build/rebuild-package.sh:33-34`: ~~`rm -rf pkg/` and `rm -rf src/`~~
  - Multiple temp file operations
- **Issue**: Destructive operations without sufficient validation
- **Risk**: Unintended file deletion if run from wrong directory
- **Status**: ✅ **RESOLVED** (2025-09-22)
- **Fix Applied**:
  - Added safety checks for PKGBUILD file presence
  - Added directory structure validation (checks for ../modules and ../startup.sh)
  - Added conditional removal (only if directories exist)
  - Temp file operations were already secure (proper mktemp usage with cleanup)
- **Verification**: Tested safety checks - script correctly rejects execution from wrong directory

---

## LOW SEVERITY ISSUES

### ⚠️ L001: Insufficient Path Validation
- **Files**: Configuration modules, filesystem navigator
- **Issue**: User paths not validated for traversal attacks
- **Risk**: Directory traversal, information disclosure
- **Status**: ❌ **OPEN**
- **Fix**: Add path sanitization and validation
- **Priority**: MEDIUM

### ⚠️ L002: Unsafe JSON Parsing
- **File**: `modules/config/json.sh`
- **Issue**: Uses sed/grep instead of proper JSON parser
- **Risk**: Potential parsing errors with malformed JSON
- **Status**: ❌ **OPEN**
- **Fix**: Use jq consistently for JSON operations
- **Priority**: LOW

---

## REMEDIATION PLAN

### Phase 1: Critical Issues (Week 1)
- [ ] Fix H001: Replace eval with safe parsing
- [ ] Fix M001: Quote all variables in critical paths
- [ ] Fix M002: Add validation for sudo operations

### Phase 2: Medium Priority (Week 2)
- [ ] Fix M003: Add file operation validation
- [ ] Fix L001: Implement path validation

### Phase 3: Low Priority (Week 3)
- [ ] Fix L002: Standardize JSON parsing
- [ ] Security review and testing
- [ ] Delete this tracking file

---

## TESTING CHECKLIST

After fixes:
- [ ] Test with malicious PKGBUILD content
- [ ] Test with paths containing special characters
- [ ] Test with malformed JSON configurations
- [ ] Verify no command injection vectors remain
- [ ] Run static analysis tools if available

---

## NOTES

### Positive Security Practices Found:
- ✅ No hardcoded secrets/credentials
- ✅ Proper IFS handling in most read operations
- ✅ Good error handling patterns
- ✅ User confirmation for destructive operations
- ✅ Uses jq for some JSON operations (inconsistently)

### CVE References:
- CVE-2014-6271, CVE-2014-7169 (Shellshock)
- CVE-2021-42740 (Command injection)
- CVE-2014-6277, CVE-2014-6278 (Additional bash injection)

---

**⚠️ IMPORTANT**: This file contains sensitive security information. Keep confidential until issues are resolved.