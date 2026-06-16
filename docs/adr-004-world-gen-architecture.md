# ADR-004: World Generation Architecture

- Date: 2026-06-16
- Status: Accepted

## Context

World generation needs to be testable and reproducible across runs.

## Decision

**World generation is a pure function: seed + params → chunk grid.** Deterministic, harness-controllable, snapshot-testable.

## Consequences

- Same seed + same params = identical world. Always.
- Generation parameters are data (not hardcoded) — the test harness can sweep them.
- Regression tests compare generated output against known-good baselines.
- The generation function has no side effects — it returns data, the caller decides what to do with it.
