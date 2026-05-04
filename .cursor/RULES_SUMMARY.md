# Yoga of Eating — Cursor Rules Summary

This project now includes **3 comprehensive Cursor rules** that encode the Swift/iOS architecture, security, and TDD guidelines from `CLAUDE.md`.

## Rules Overview

### 1. **swift-architecture-standards.mdc**
Core MVVM, SOLID principles, dependency injection, and code quality standards for all Swift files.

**Key Topics:**
- TDD discipline (Red-Green-Refactor cycle)
- MVVM compliance (Views → ViewModel → Services)
- Dependency injection via protocols
- SOLID principles (SRP, OCP, DIP)
- Centralized strings (`Strings.swift`) and fonts (`FontTheme`)
- File organization and line limits
- Build quality (zero warnings)
- Testing strategy and mocks

**Applies to:** `**/*.swift` files

---

### 2. **security-data-protection.mdc**
Authentication, authorization, data protection, and security best practices.

**Key Topics:**
- Authentication guards (all user data access)
- User data isolation (users can only access their own data)
- Sensitive data handling (no logging, caching, plaintext storage)
- Network security (HTTPS enforcement)
- Secrets management (Keychain, not UserDefaults)
- Input validation & sanitization
- Error handling (no information disclosure)
- Firestore Security Rules
- HealthKit privacy best practices
- Tab view security (Principle of Least Privilege)

**Applies to:** `**/*.swift` files

---

### 3. **tdd-testing-strategy.mdc**
Test-Driven Development methodology and testing patterns for the project.

**Key Topics:**
- TDD cycle (Red-Green-Refactor)
- Test organization (one file per behavior area)
- Shared mocks in `Mocks.swift`
- Mock strategy (boundaries, not internals)
- @MainActor requirement for ViewModel tests
- Async testing patterns
- Test isolation and independence
- Common pitfalls and anti-patterns
- Regression tests (AI analysis wiring)
- Security and validation tests

**Applies to:** `**/*Tests.swift` files

---

## How These Rules Work

1. **When you open a Swift file**, Cursor will automatically apply the relevant rules
2. **Rules provide context** for the AI agent to enforce standards
3. **No hardcoding** of guidelines in comments—rules are in one place
4. **Searchable**: All standards can be referenced without digging through CLAUDE.md

## Key Alignments with CLAUDE.md

| CLAUDE.md Section | Cursor Rule |
|---|---|
| TDD rules — non-negotiable | tdd-testing-strategy.mdc |
| SOLID & Design Principles | swift-architecture-standards.mdc |
| Cybersecurity & Data Protection | security-data-protection.mdc |
| Centralized Resources & Theming | swift-architecture-standards.mdc |
| Build warnings policy | swift-architecture-standards.mdc |
| Critical regression tests | tdd-testing-strategy.mdc |

---

## Using These Rules

### For Code Review
Reference these rules when reviewing Swift PRs:
- ✅ Do tests follow TDD discipline?
- ✅ Is MVVM enforced?
- ✅ Are all strings centralized?
- ✅ Are security guards in place?
- ✅ Are mocks used correctly?

### For Development
When implementing a feature:
1. Read **tdd-testing-strategy.mdc** first (write tests before code)
2. Follow **swift-architecture-standards.mdc** (MVVM, SOLID, DI)
3. Apply **security-data-protection.mdc** (auth guards, data isolation)

### For Onboarding
New team members can reference `.cursor/rules/` instead of hunting through CLAUDE.md.

---

## Next Steps

1. **Verify rules are loading**: Open a `.swift` file and check the Cursor rule picker (should show all 3 rules)
2. **Test enforcement**: Start implementing a new feature using TDD—Cursor will remind you of standards
3. **Update as needed**: These rules can evolve as the project matures
4. **Add more rules**: If new areas emerge (e.g., Firebase conventions, UI patterns), create additional `.mdc` files

---

## File Locations

```
/Users/sunil/Downloads/YogaofEating/
├── .cursor/
│   ├── rules/
│   │   ├── swift-architecture-standards.mdc
│   │   ├── security-data-protection.mdc
│   │   ├── tdd-testing-strategy.mdc
│   │   └── RULES_SUMMARY.md (this file)
│   └── settings.json
├── CLAUDE.md (source of truth)
├── Yoga of Eating.xcodeproj/
└── ...
```

---

## Questions?

All three rules are derived from CLAUDE.md and encode the core project standards. If a rule needs updating, reference CLAUDE.md as the source of truth.
