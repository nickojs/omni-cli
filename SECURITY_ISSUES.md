# Security Issues Tracking

**Status**: In Progress
**Created**: 2025-09-22
**Last Updated**: 2025-09-22

> **Note**: This file tracks security vulnerabilities found in the fm-manager project. Delete this file once all issues are resolved.

## Summary
- **Critical**: 0 issues
- **High**: ~~1~~ 0 issues (1 resolved ✅)
- **Medium**: 3 issues
- **Low**: 2 issues
- **Total**: 6 issues (1 resolved, 5 remaining)

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

### ⚠️ M001: Unquoted Variable Expansion
- **Files**: Multiple locations
  - `build/rebuild-package.sh:30`: `sudo pacman -U $pkgname-$pkgver-$pkgrel-any.pkg.tar.zst`
  - `startup.sh` and various modules
- **Issue**: Variables used without quotes in commands
- **Risk**: Command injection via word splitting/glob expansion
- **CVE**: Related to CVE-2021-42740
- **Status**: ❌ **OPEN**
- **Fix**: Quote all variable expansions
- **Priority**: HIGH

### ⚠️ M002: Privilege Escalation Risk
- **File**: `build/rebuild-package.sh:30`
- **Code**: `sudo pacman -U $pkgname-$pkgver-$pkgrel-any.pkg.tar.zst`
- **Issue**: sudo with unquoted variables from untrusted source
- **Risk**: Installation of arbitrary packages
- **Status**: ❌ **OPEN**
- **Fix**: Validate variables before sudo operations
- **Priority**: HIGH

### ⚠️ M003: Unsafe File Operations
- **Files**:
  - `build/rebuild-package.sh:11-12`: `rm -rf pkg/` and `rm -rf src/`
  - Multiple temp file operations
- **Issue**: Destructive operations without sufficient validation
- **Risk**: Unintended file deletion
- **Status**: ❌ **OPEN**
- **Fix**: Add path validation before destructive operations
- **Priority**: MEDIUM

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