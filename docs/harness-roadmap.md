# Harness Roadmap

This roadmap describes when to extend the harness.

## Current Level

The current template includes:

- stage skills
- work outputs
- safety gates
- output quality gates
- build/test gate (executes real build/test; sets testPassed by execution, not self-report)
- execution logs
- wiki draft extraction
- failure lesson collection (run manually; not auto-run inside gates)
- manual wiki promotion checks

## Deferred Automation

Do not automate these yet:

- wiki index generation
- wiki promotion
- PR approval
- deployment decisions
- destructive operations
- secret or environment file mutation

## Future Work

### Wiki Index

Add when:

- total approved wiki documents exceed 10
- or a single category has at least 3 approved documents
- or people repeatedly cannot find documents

### Wiki Freshness

Add when:

- docs drift from code
- old reviewed dates create confusion
- policies change but old docs remain active

### Lesson Promotion

Add when:

- lesson drafts accumulate
- the same model assumption failure repeats
- lessons do not become updated rules

### Test Harness Profiles

Add when:

- test commands repeat across tasks
- failure reproduction differs by person
- browser or API checks become routine

### Operational Check Profiles

Add when:

- health, config, scheduler, or external dependency checks repeat
- deployment readiness checks are missed

## Principle

Add automation after repeated friction is observed. The harness assists decisions; humans make final approvals.
