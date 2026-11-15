# NyxAstro — Ubuntu Touch / NyxOS Flavor
## New-thread handoff seed — 2026-11-15

> **Purpose:** Resume the Astro Slide 5G Ubuntu Touch port on **The Beast** without mixing it with NyxCore Sight or the proposed EchoTerra/SynthCoding RPG. Treat this document as a handoff of previously reported observations, **not as a fresh machine audit**.
>
> **Current focus:** Investigation **92DD**, actual Linux USB gadget ConfigFS compatibility in a disposable **offline x86-64 Ubuntu guest**. The immediate unresolved item is **C5R1**. **No physical Astro flashing is authorized by this handoff.**

## 1. North star and working style

- Target device: **Astro Slide 5G**. Long-term goal: port **Ubuntu Touch** with a **NyxOS-flavored experience**, diagnose hardware and boot issues, improve the port, and eventually upstream appropriate fixes. The target cellular carrier is **T-Mobile US**; cellular bands, modem, and VoLTE must be measured rather than assumed.
- Working computer: **The Beast** (Ubuntu Linux). Focus on isolated Docker/Git builds and offline QEMU experiments before touching the phone.
- The user likes a collaborative **SynthCoding** workflow: explicit hypotheses, small experiments, host+guest terminal 'double dribble', real evidence, careful Git scopes, and human approval before commits, merges, deployments, or flashing.
- **No root/host ConfigFS modifications, physical USB passthrough, USB UDC binding, network access inside the guest, or changes to the actual Astro** in the current 92DD experiments.
- **Separate systems:** NyxCore/Nyx Show is being developed in another thread. EchoTerra RPG ideas are parked. This thread is **Ubuntu Touch only**.

## 2. Accepted, preserved engineering checkpoint (92DC)

Repository: `~/Projects/astro-linux/astro-diagnostic-v02-lab`

- Branch: `feat/halium11-diagnostic-v02`
- Accepted local HEAD: `5cb126721a9e663ddedee1f907ec689089371ef3`
- Investigation **92DC — ConfigFS Filesystem Boundary Hardening**: human-accepted, **locally committed**. **Not pushed or remote-release sealed** according to available history.
- Two committed files and fingerprints:

  | File | SHA256 |
  |---|---|
  | `diagnostic/v054/init.c` | `f9cf542b182e03d443a30502eb2af0d69f2ab016e60df0970e670a7cbcdb6542` |
  | `diagnostic/v054/tests/test_configfs_boundaries.py` | `c3aee66b3dc2d6d319044c1ad7f6bc02e3aac4e229b110f862556137bef56741` |

- Final 92DC reports passed the existing ARM64 offline diagnostic regressions, including **21 boundary cases**: symlinks, hardlinks, permission/type checks, and statx faults. These were largely **synthetic** fixtures, **not proof** of real kernel ConfigFS compatibility.
- Known unrelated untracked directories from previous host checks: `diagnostic/__pycache__/`, `diagnostic/v02/`, `v03/`, `v04/`, `v041/`, `v05/`, `v051/`. **Do not delete or sweep these.** Git status may be unclean only because of those unrelated untracked paths; check tracked diffs independently.
- Earlier NyxAstro milestones include the NyxAstro ARM64 `/init` and offline initramfs diagnostic; do not confuse the current guest x86-64 ConfigFS test with an ARM64 phone boot.

## 3. Offline QEMU lab — verified foundation

Host lab: `~/VMs/nyxastro-92dd`

- Installed guest: **Ubuntu Server 24.04.3 LTS**, kernel `6.8.0-71-generic`, guest hostname `nyxvm`, login `nyxterm`.
- Base image: `ubuntu-92dd-base.qcow2` (20 GiB virtual QCOW2). **Preserved SHA256:** `1efea2f5d0470879b04ad303d33c6cc7ee5892c37a7a1d935cf2c509f4a6bece`.
- Boot method: QEMU/KVM `qemu-system-x86_64`, Q35, OVMF firmware, guest-specific UEFI vars, base-backed **disposable QCOW2 overlay**. No networking (`-nic none`), no USB passthrough, no UDC hardware.
- Diagnostic transport: script on a **read-only ISO9660 virtual CD-ROM** mounted in guest using `sudo mount -o ro /dev/sr0 /mnt`. Guest invokes `sudo bash /mnt/inspect.sh` and streams output to host via QEMU `-serial file:<host-log>` (typically `/dev/ttyS0` inside guest). Shutdown with `sudo poweroff`.
- Base disk remains untouched by guest overlays; host verifies its hash after each run. Host ConfigFS `/sys/kernel/config` was never written by these tests.
- The guest can sometimes appear to hang in `systemd-networkd-wait-online.service` because it has no NIC; do not interpret this as a ConfigFS test failure.

## 4. Investigation 92DD — tested versus unresolved

| Gate | Actual outcome | Meaning |
|---|---|---|
| **C1** offline ISO/serial transport | **PASS** host + guest | Read-only script delivery and serial evidence collection work. |
| **C2** `libcomposite` activation | **PASS** host + guest | `/sys/kernel/config/usb_gadget` appeared after loading module; initially absent. |
| **C3** real gadget topology | **PASS** host + guest | Creating temporary gadget exposed kernel-generated `strings`, `configs`, `functions`, `idVendor`, `idProduct`, `UDC` etc.; config instance auto-created its `strings`; reverse cleanup passed. |
| **C4** real ACM function instance | **PASS** host + guest | Created `functions/acm.usb0`; kernel-supplied `port_num=0`, mode `444`, links `1`; removed function/gadget; no UDC or config link. |
| **C5** ACM config symlink using relative target | **FAIL** (informative) | Kernel rejected `ln -s ../../functions/acm.usb0 <.../configs/c.1/acm.usb0>` with **`No such file or directory` (ENOENT)**; script cleaned up all guest artifacts successfully. |
| **C5R1** corrected link using absolute target | **INCONCLUSIVE** | New runner generated a fresh guest overlay but host's serial log captured **only UEFI startup messages**, with no guest script headings or PASS/FAIL. Cannot infer success or failure of the corrected symlink. |

### C5 root-cause hypothesis

The C5 runner uses `ln -s -- ../../functions/acm.usb0 "$L"`. On the real ConfigFS interface, relative link-target resolution may differ from ordinary filesystem assumptions. The proposed C5R1 correction is `ln -s -- "$F" "$L"`, using the existing ACM function's absolute path. **This correction has NOT been proven yet.** The v0.5.4 source reportedly contains a similar relative `symlinkat()` target; **do not edit the accepted checkpoint until the real-kernel behavior is verified and a new controlled investigation is scoped.**

### C5 failed evidence (retain)

- Serial: `~/VMs/nyxastro-92dd/92dd-c5-serial.log` (~1,390 bytes)
- Failure line: `ln: failed to create symbolic link .../configs/c.1/acm.usb0: No such file or directory`
- Final guest: `NYXASTRO 92DD-C5 ACM CONFIG LINK: FAIL`
- Cleanup explicitly removed config, ACM function, and gadget.

### 92DD-C5R1 inconclusive evidence (retain)

- Runner originally saved: `~/Downloads/nyxastro_92dd_c5r1_absolute_link.txt` SHA256 `92db2ac9c40d84d600f805e4cbcb300f5aec705b8e368cff7a65e989f0009553`.
- `~/VMs/nyxastro-92dd/92dd-c5r1.iso` SHA256 `1f3659a8894a0441fe315c4333a9a8031d3d4fb9bee864d487d0fac3401be543`.
- `~/VMs/nyxastro-92dd/92dd-c5r1-payload/inspect.sh` SHA256 `34226e7f2c0def82b5cbfe844b51efe6243c323ae3308bad5af7d180325c3708`.
- `~/VMs/nyxastro-92dd/ubuntu-92dd-c5r1.qcow2` (disposable overlay) and `OVMF_VARS-c5r1.fd` (guest-specific vars).
- `~/VMs/nyxastro-92dd/92dd-c5r1-serial.log` **410 bytes**: UEFI `BdsDxe`/`EFI stub` messages **only**; no evidence that `inspect.sh` ran. Host `qemu-img check` on overlay passed, base hash passed, but final evidence gate failed.
- Previous assistant proposed **replaying the existing C5R1 overlay/ISO with a new, non-overwriting serial log**. **No results from that replay are yet reported.** Don't treat the suggested replay as performed.

## 5. Recommended FIRST gate in the new thread

**Do not jump to code changes or actual-phone flashing.** First inspect the existing C5R1 runtime/evidence safely. This block is host-only and read-only:

```bash
(
set -euo pipefail
cd "$HOME/Projects/astro-linux/astro-diagnostic-v02-lab"
LAB="$HOME/VMs/nyxastro-92dd"
printf '\n===== BRANCH / COMMIT / TRACKED DIFF =====\n'
git branch --show-current
git rev-parse HEAD
git diff --name-status
git diff --cached --name-status
printf '\n===== ACCEPTED SOURCE FINGERPRINTS =====\n'
sha256sum diagnostic/v054/init.c diagnostic/v054/tests/test_configfs_boundaries.py
printf '\n===== BASE FINGERPRINT =====\n'
sha256sum "$LAB/ubuntu-92dd-base.qcow2"
printf '\n===== EXPERIMENT FILES =====\n'
ls -lh "$LAB"/92dd-c5*-serial.log "$LAB"/92dd-c5r1.iso "$LAB"/ubuntu-92dd-c5r1.qcow2
printf '\n===== C5R1 SCRIPT LINK LOGIC =====\n'
grep -nE 'ln -s|cleanup|trap|tee|ttyS0|PASS|FAIL' "$LAB/92dd-c5r1-payload/inspect.sh" || true
printf '\n===== C5R1 SERIAL (VISIBLE TEXT) =====\n'
cat -v "$LAB/92dd-c5r1-serial.log"
printf '\nREAD-ONLY AUDIT COMPLETE\n'
)
```

Then decide with the human whether to conduct a carefully gated **C5R1 replay** in the same disposable overlay, using a **new** serial log and preserved original C5/C5R1 evidence. Replay inside guest typically needs only:

```bash
sudo mount -o ro /dev/sr0 /mnt
sudo bash /mnt/inspect.sh
echo "DIAGNOSTIC_EXIT=$?"
# Check actual printed output; then:
sudo poweroff
```

Guard against accidentally booting more than one VM on the same overlay; verify the base image SHA, overlay integrity and Git tracked diff after. If replay remains inconclusive, investigate whether guest login/mount/script invocation or serial forwarding was skipped before changing the ConfigFS hypothesis. **A guest screen photo is useful if diagnostics never display.**

## 6. If C5R1 eventually passes

- Preserve both old failed evidence and corrected passing evidence.
- Open **92DD-C6** as a separate controlled **v0.5.4 compatibility review**, with a new candidate version/branch or isolated worktree and explicit test coverage of the verified absolute path behavior.
- Re-run existing offline ARM64 synthetic regressions AND new relevant Linux kernel interface tests. Test rollback, cleanup, object type, failure behavior and privileges; do not assume the guest x86-64 proves the Astro ARM64 kernel behaves identically.
- Request explicit human acceptance prior to Git commit/merge/tag or any hardware boot/flashing step.

## 7. Status / limitations

- **92DC is the accepted local checkpoint** and must remain intact.
- **92DD-C1–C4 passed**, **C5 failed**, **C5R1 unresolved**.
- **No Ubuntu Touch boot on Astro Slide has been demonstrated** by these tests. No physical-device USB gadget, camera, display, Wi-Fi, cellular/VoLTE, or full OS functionality is proven.
- Target objective remains progressive hardware enablement with reproducible diagnostics, not a rushed flash.
- Separate NyxCore/Sight and EchoTerra work has its own new thread; do not pull RPG/SynthCoding implementation into this porting gate.

## 8. Opening message for new Ubuntu Touch thread

> **Nyx, resume the Astro Slide Ubuntu Touch/NyxOS-flavor port from this handoff. We have accepted 92DC at `5cb1267` and verified 92DD-C1–C4. C5's relative ConfigFS ACM symlink failed with ENOENT and cleaned up; C5R1's absolute-path correction remains inconclusive because its 410-byte serial log contains only UEFI boot messages. Keep The Beast host, guest base image, accepted Git, and physical Astro protected. Start with a read-only state/evidence gate, then help me safely replay C5R1 if warranted. Don't claim completion until guest and host evidence agree. This is Ubuntu Touch work only; keep NyxCore/SynthCoding RPG in the separate thread.**

---

*Handoff prepared from the reported terminal history and prior accepted checkpoints. No host commands executed as part of creating this document.*
