# Exact recording commands

After extracting the archives into the paths in README, open PowerShell and run:

```powershell
. 'C:\ai_workflow_acceptance\ACC003\run-kit\commands\Common.ps1'
```

Run numbered command scripts in RUN_PLAN order. Save actual AI replies and exact sent prompts in `$Project\evidence\` using UTF-8 without BOM. Never use default Windows PowerShell 5 `Out-File` for R/CSV/JSON bytes (its default encoding can change content). Prefer the browser's file download, byte-identical copy, or .NET `UTF8Encoding($false)` for text the AI produced. Do not change frozen CSV bytes. Code extraction is the complete fenced R content, not an edited repair.

## Design and owner approval

Save ChatGPT's complete candidate as `$Project\design.json` (retain older candidate copies in evidence if changed). Save the independent accepting review in `$Project\reviews\design-actual.txt`. Only invoke the acceptance recorder if the reviewer actually ACCEPTED this exact candidate; REVISE is not accepted.

```powershell
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\refresh_view.R'), $Repo, $Project)
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\inspect.R'), $Repo, $Project, 'design')
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\record.R'), $Repo, $Project, 'design-review', (Join-Path $Project 'reviews\design-actual.txt'), 'Grok')
```

Show the owner: the question; population; metric/filter/missingness rules; threshold/ranking/capacity; expected main fixture result; no model; review disposition; and the exact DESIGN_SHA256 above. Ask once: **“Approve this Stage 3 contract for ACC003?”** Save the actual direct response in `$Project\evidence\owner-actual.txt`. Set `$ApprovalWords` to its exact approving words, e.g. `Approved` only if that is what the owner said. Do not substitute a prepared answer.

```powershell
$ApprovalWords = 'Approved' # REPLACE with actual verbatim approval if different
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\record.R'), $Repo, $Project, 'owner-approval', (Join-Path $Project 'evidence\owner-actual.txt'), $ApprovalWords)
& "$Kit\commands\03-Lock.ps1"
```

If the owner declines or changes a rule, do not invoke lock. Resolve that reserved decision. The machine verifies the recorded text/hash, not human identity or conversational meaning.

## Builder capture

For each actual reply, save the complete reply and sent prompt. Save the exact R code block into an evidence `.R` file. Supply the actual visible model name (use `unknown-not-displayed` if genuinely unavailable, disclosed in report) and actual chat URL/identifier. Do not fabricate a model version. Invoke below only when the coordinator can truthfully attest the builder received no peer solution; otherwise report the exposure.

```powershell
$AModel = 'REPLACE_WITH_ACTUAL'; $AChat = 'REPLACE_WITH_ACTUAL'
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\record.R'), $Repo, $Project, 'builder', 'R-A', (Join-Path $Project 'evidence\RA-captured.R'), (Join-Path $Project 'evidence\RA-reply.txt'), $AModel, $AChat, (Join-Path $Project 'evidence\RA-prompt.txt'))
$BModel = 'REPLACE_WITH_ACTUAL'; $BChat = 'REPLACE_WITH_ACTUAL'
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\record.R'), $Repo, $Project, 'builder', 'R-B', (Join-Path $Project 'evidence\RB-captured.R'), (Join-Path $Project 'evidence\RB-reply.txt'), $BModel, $BChat, (Join-Path $Project 'evidence\RB-prompt.txt'))
& "$Kit\commands\04-Validate.ps1"
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\inspect.R'), $Repo, $Project, 'validation')
```

The recorder preserves previous code versions and prompt/reply files; the current attempt binds exact code and inputs. `validate` runs the real builders, fixtures and invariance. On a repair, use new evidence filenames, call the same builder recorder and rerun `04-Validate.ps1`; do not patch the peer implementation. Do not count a failed invocation as a passed check.

## Finish

Send prompt09 with actual validated files and exact paths. Save returned JSON as `$Project\finish.json`, with no invented review acceptance fields. Run:

```powershell
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\inspect.R'), $Repo, $Project, 'finish')
```

Supply that FINISH_CONTENT_SHA256 with the exact content to prompts10/11. Record each actual accepting review immediately against the content it reviewed. Do not run an acceptance recorder after changing substantive content unless that reviewer verified the changed content. The review record fields do not affect the content hash.

```powershell
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\record.R'), $Repo, $Project, 'finish-review', 'inference_review', (Join-Path $Project 'reviews\finish-inference-actual.txt'))
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\record.R'), $Repo, $Project, 'finish-review', 'numerical_review', (Join-Path $Project 'reviews\finish-numbers-actual.txt'))
& "$Kit\commands\05-Finish.ps1"
& "$Kit\commands\06-Certify.ps1"
```

For a consolidated correction, retain prior finish.json/replies in evidence; use prompt12 and affected-content verification only. Inspect new content hash; then record the updated actual acceptance. No need for another full audit.

## Repairs / escalation

Record a repair result after the actual rerun. Preserve its explanation/console in an evidence text file. Replace example identifiers with the actual stable defect ID and path.

```powershell
Run-R -Arguments @((Join-Path $Repo 'acceptance\acc003\record.R'), $Repo, $Project, 'repair', 'DEFECT-actual', 'UNSUCCESSFUL', (Join-Path $Project 'evidence\repair-actual.txt'))
```

At the third unsuccessful repair the recorder returns exit2 with ESCALATE_TO_OWNER. This is an operational pause, not ANALYSIS_DEFECT. No fourth repair without a ruling. SUCCESS records a successful fix; retain earlier failed attempts. For checker changes use prompt15, then affected pretests/rechecks supplied with the repair. If pretest identity changed, `run_pretest.R REPO PROJECT` runs the frozen pretests again in a new directory; do not reuse an inapplicable report.

## Finish interface and transport fallbacks (ACC003 lessons)

Before review sends, parse the actual saved finish.json and check the field types listed in prompt 09. This avoids spending review sends on a known-incompatible representation. This read-only check records no PASS and does not replace 05-Finish. inspect.R finish provides a content hash, not complete interface validation. For a pure representation repair use prompt 12; for checker/configuration defects use prompt 15. Preserve old JSON/reviews; no incidental wording changes; bind actual affected-content verification to the new hash.

If a service refuses ZIP attachments, provide the same permitted text files as a bundle with clear BEGIN/END file boundaries, original project-relative paths and SHA256 headers. Verify each bundled payload against the original bytes when encoding permits; disclose any transport newline/encoding normalization. Original files remain the hash authority. Do not claim a text bundle reproduces binary files. Never broaden a builder packet to work around an upload failure.

If download fails, capture the complete code/JSON block directly from the clipboard to UTF-8 without BOM, without retyping or semantic editing. Preserve the original reply and the captured artifact, verify completeness against the full displayed block, compute its hash, and check copied/transferred bytes against that hash. If original download bytes are unavailable, say so: a captured-file hash cannot prove equality to an unavailable download. Recapture uncertain/truncated output; first/last-line checks alone do not establish full fidelity.

If a session logs out, preserve role/chat identity and resume that same chat after authentication. Existing authorized sessions may be resumed; new credentials or authority go to the owner. No silent account/service substitution. Preserve the interrupted attempt. Capture commands and PowerShell logs with their actual encoding; use explicit Get-FileHash rather than aliases that may collide.

Before live builder sends, follow run-kit/README.md's access restriction: isolated fresh chats, no supplied repo/reference/oracle context, external-access tools disabled where available. Record actual tool settings or inability to enforce them in the existing independence declaration/evidence. A no-access prompt is procedural control, not proof of disabled tools. Actual forbidden reference access must not be recorded as independent. The canonical oracle is workflow/acceptance/acc003/fixtures/oracle.json, copied by prepare.R to the project; do not look for it in run-kit/fixtures.
