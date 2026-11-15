# NyxAstro — Ubuntu Touch Port
## Investigation 92DD / C6.8 — G8 Handoff Seed

**Date:** 2026-11-15
**Host:** The Beast, Ubuntu Linux
**Target:** Astro Slide 5G
**Status:** Experimental handoff — not release accepted
**Next gate:** C6.8-G8-R1 ARM64 synthetic testing

> This seed preserves observations reported through C6.8-G8.
> It is not a fresh host audit or proof of device functionality.

## 1. Project objective

Port Ubuntu Touch to the Astro Slide 5G, diagnose device
integration problems, improve hardware functionality, and
eventually contribute appropriate fixes upstream.

An optional NyxOS-flavored experience remains a future goal.

T-Mobile US cellular compatibility, modem support, LTE/5G,
VoLTE, display, camera, Wi-Fi, and other hardware functionality
require independent verification.

## 2. Engineering workflow

Use isolated Git worktrees, pinned Docker environments,
offline QEMU experiments, controlled ARM64 diagnostics,
source fingerprints, and explicit human acceptance.

The Beast is the development host.

NyxCore is a separate infrastructure project.

No physical Astro flashing, real-device Ubuntu Touch boot,
production ConfigFS modification, or UDC binding has been
established by this investigation.

## 3. Accepted baseline — 92DC

Repository:

~/Projects/astro-linux/astro-diagnostic-v02-lab

Branch:

feat/halium11-diagnostic-v02

Accepted local commit:

5cb126721a9e663ddedee1f907ec689089371ef3

Accepted source:

diagnostic/v054/init.c

SHA256:

f9cf542b182e03d443a30502eb2af0d69f2ab016e60df0970e670a7cbcdb6542

92DC was human-accepted and locally committed.

Do not infer remote publication or release sealing.

## 4. Current experimental worktree

Repository:

~/Projects/astro-linux/astro-diagnostic-v055-lab

Branch:

feat/halium11-diagnostic-v055-candidate

Base:

5cb126721a9e663ddedee1f907ec689089371ef3

Reported Git status:

?? diagnostic/v055/

Tracked and staged diffs were empty during the last
reported source-integrity checks.

All v0.5.5 candidates remain experimental and uncommitted.

## 5. Real-kernel ConfigFS findings

Investigation 92DD used an offline Ubuntu x86-64 guest
with disposable storage and no physical USB connection.

C1-C4 demonstrated the prerequisite diagnostic operations.

C5 exposed a relative-symlink creation failure.

C5R1 established that an absolute target could succeed.

C5R2 demonstrated that creating the relative link while
the working directory was the configuration directory
could also succeed.

These are guest-kernel observations, not Astro ARM64
hardware compatibility proofs.

## 6. C6.8 candidate progression

The first v0.5.5 candidate used fchdir() to control
relative-link resolution.

Injected restoration failure demonstrated that process
working-directory state could remain changed after
partial success.

An alternative absolute-path candidate removed the
working-directory dependency.

Its original synthetic regression suite passed 21/21.

However, further tests identified path-substitution
and partial-mutation concerns.

## 7. Verified experimental results

### C6.8-E

Three synthetic ARM64 scenarios were observed:

- Normal link creation succeeded.
- Injected symlinkat failure created no link.
- Injected late close failure reported failure while
  leaving the created link present.

### C6.8-F

A substituted target demonstrated that the absolute-path
synthetic scaffold could report success despite linking
to an unintended object.

### C6.8-G2

Created an experimental object-identity guard using
directory descriptors, statx(), and bounded unlinkat()
rollback attempts.

### C6.8-G3

Normal association succeeded.

Substitution with a regular-file target was rejected,
and the configuration link was removed.

### C6.8-G4

Substitution with another valid directory was rejected.

Both statx calls succeeded, different inode identities
were detected, and rollback succeeded.

### C6.8-G5

Injected unlinkat EACCES caused:

NYXASTRO ACM LINK: ROLLBACK INCOMPLETE

The scaffold reported failure, and the remaining link
was detected. This is correct failure reporting, not
successful cleanup.

### C6.8-G6

Three synthetic scenarios passed:

- Control: normal identity accepted.
- First statx failure: rejected, link removed.
- Second statx failure: rejected, link removed.

### C6.8-G7

A simulated EIO from the target descriptor close,
after successful verification, caused scaffold failure.

The configuration link remained.

No rollback was attempted.

### C6.8-G8

A separate candidate was assembled to attempt
unlinkat rollback when the original target descriptor
close reports a late error.

Assembly passed.

ARM64 runtime testing of G8 has NOT occurred.

## 8. Source provenance

G2 candidate:

diagnostic/v055/init_absolute_guard_g2.c

SHA256:

2e3a3dff8cabec20e664488c29f4fd9c73976bdc9e261f9c009976a4b62166c6

G8 candidate:

diagnostic/v055/init_absolute_guard_g8.c

SHA256:

3ace4a432beb9db66a43c24cbf3702cfb838c441b540a93b2da8005c42e41b54

These fingerprints were reported by The Beast terminal.

## 9. Unresolved engineering questions

- Final configuration-directory close failure.
- Root descriptor close failure.
- Concurrent replacement between validation and rollback.
- Ownership verification before removing a created link.
- Additional failure paths and incomplete cleanup.
- Real ConfigFS-specific object association semantics.
- ARM64 kernel behavior on the physical Astro.
- Permanent regression coverage for C6.8-G3 through G8.

Synthetic QEMU user-mode testing is not a substitute
for testing the actual kernel filesystem interface.

## 10. Next gate — C6.8-G8-R1

Execute three bounded ARM64 synthetic scenarios:

1. Normal identity and successful link creation.
2. Target-close error with successful rollback.
3. Target-close error with rollback failure.

Required evidence includes syscall injection counters,
diagnostic messages, filesystem state, and source hashes.

No test result may be presumed before execution.

## 11. Acceptance and publishing rules

Preserve accepted v0.5.4 and all candidate sources.

Keep original investigation seeds as historical records.

Use separate as-built documentation for implementation
that has actually been verified and human-accepted.

Publishing this seed to GitHub records engineering
history; it does not accept or release v0.5.5.

No candidate Git commit, merge, release tag, device flash,
or production deployment is authorized by this document.
