# JidoBuilder — Page-by-Page OCD Sweep Plan

## Context

8 of 41 pages have been browser-verified. 33 remain. Every single page must receive full interaction testing — every button clicked, every form filled and submitted, every dropdown opened, every result verified with screenshot proof. No shortcuts. No "rapid." No skipping.

The previous sweep was too fast. This plan enforces methodical, obsessive, one-page-at-a-time verification with mandatory proof at every step.

---

## PROTOCOL (Per Page — NO EXCEPTIONS)

```
FOR PAGE X:
  STEP 1: Navigate to the page. Wait for full load. Screenshot.
  STEP 2: Read the page aloud — what is the title, what elements exist,
           what sidebar item is highlighted.
  STEP 3: For EVERY interactive element on the page (top to bottom, left to right):
    a. Identify it (button/form/link/dropdown/input/toggle)
    b. Click it / fill it / open it
    c. Wait for response
    d. Screenshot the result
    e. Document: "Element X: [what happened]"
    f. If the element FAILED or produced wrong output:
       - Read the source code
       - Fix the code
       - Recompile
       - Restart server if needed
       - Re-navigate to the page
       - Re-test the EXACT element
       - Screenshot the fix
       - ONLY THEN continue to next element
  STEP 4: Scroll to bottom of page. Screenshot. Verify footer/attribution visible.
  STEP 5: Answer the three M.H. Standard questions:
    - VALUE: What real task can a user accomplish?
    - FUNCTION: Did every element work?
    - POLISH: Would M.H. approve?
  STEP 6: Record verdict: PASS / FAIL / CONDITIONAL PASS (with specific reason)
  STEP 7: If any fix was made: compile, test, commit for THIS page only
  STEP 8: Update todo list marking this page complete
  STEP 9: ONLY THEN move to next page
```

## BLOCKING RULES

- I CANNOT move to page N+1 until page N has a verdict
- I CANNOT say "this is similar to X, skipping"
- I CANNOT screenshot without waiting for full load
- I CANNOT mark PASS without having clicked every interactive element
- I CANNOT skip scrolling to verify content below the fold
- Every form on every page must be FILLED and SUBMITTED
- Every button must be CLICKED and the result OBSERVED
- Every dropdown must be OPENED and options VERIFIED
- Every link must be CLICKED and navigation CONFIRMED
- Every empty state must be SEEN and its message VERIFIED

---

## PAGE ORDER (All 41)

Pages already verified (8) — these are DONE and will NOT be re-tested:
1. `/` — Dashboard ✓
2. `/roster` — Agents ✓
3. `/assignments/new` — Dispatch Signal ✓
4. `/workflows` — Workflows ✓ (conditional)
5. `/notebook` — Notebook ✓
6. `/memory` — Memory Spaces ✓
7. `/active-inference` — Active Inference ✓
8. `/debug` — Debug ✓

### Remaining 33 pages to sweep (in sidebar order):

**OPERATE:**
9. `/schedules` — Schedules

**CONFIGURE:**
10. `/templates` — Templates
11. `/skills` — Skills Catalog
12. `/directives` — Directives Builder
13. `/teams` — Teams (Pods)
14. `/identity` — Identity Profiles
15. `/work-styles` — Work Styles
16. `/skills-manager` — Skills Manager
17. `/llm-config` — LLM Config

**BUILD:**
18. `/blocks` — Blocks
19. `/state-ops` — State Ops
20. `/hierarchy` — Hierarchy
21. `/pools` — Pools
22. `/threads` — Threads
23. `/factory` — Factory

**OBSERVE:**
24. `/execution` — Execution Monitor
25. `/traces` — Traces
26. `/audit` — Audit
27. `/metrics-dashboard` — Metrics

**ADMIN:**
28. `/settings` — Settings
29. `/workspaces` — Workspaces
30. `/vault` — Vault
31. `/watchers` — Watchers
32. `/error-policy` — Error Policy
33. `/capability-packs` — Capabilities
34. `/solutions` — Solutions
35. `/template-library` — Template Library
36. `/marketplace` — Marketplace

**HELP:**
37. `/guide` — User Guide (scroll every section, verify About)
38. `/glossary` — Glossary (verify all 22 terms)
39. `/onboarding` — Onboarding (step through wizard)

**DETAIL PAGES:**
40. `/agents/:id` — Agent Detail (navigate from roster View link)
41. `/agents/:id/chat` — Agent Chat (type message, send, verify response)

---

## DEFECT LOG

Every defect found during the sweep gets logged here with:
- Page URL
- Element that failed
- What happened vs what should happen
- Whether it was fixed during the sweep or deferred
- If fixed: the file changed and the commit hash

(Populated during execution)

---

## COMPLETION CRITERIA

The sweep is DONE when:
1. All 41 pages have a verdict (PASS / CONDITIONAL PASS with reason)
2. All defects found are either FIXED or DOCUMENTED with reason for deferral
3. Final `mix compile --warnings-as-errors` passes
4. Final `mix test` — 0 failures
5. Final `mix assets_build` — clean
6. Final commit with sweep summary
7. Complete defect log published

---

## ESTIMATED ELEMENTS PER PAGE

Some pages have many elements, some have few. Rough counts:

| Page | Buttons | Forms | Dropdowns | Links | Total |
|------|---------|-------|-----------|-------|-------|
| Schedules | 2 | 1 | 1 | 0 | 4 |
| Templates | 2 | 0 | 0 | 2+ | 4+ |
| Skills | 1 | 1 | 0 | 1+ | 3+ |
| Directives | 2 | 1 | 1 | 0 | 4 |
| Teams | 2 | 1 | 1 | 0 | 4 |
| Identity | 2 | 1 | 1 | 1 | 5 |
| Work Styles | 0 | 0 | 0 | 0 | 1 (display) |
| Skills Mgr | 2 | 0 | 0 | 5 | 7 |
| LLM Config | 1 | 1 | 2 | 0 | 4 |
| Blocks | 1 | 1 | 0 | 0 | 2 |
| State Ops | 1 | 1 | 1 | 0 | 3 |
| Hierarchy | 2 | 1 | 2 | 0 | 5 |
| Pools | 0 | 0 | 0 | 0 | 1 (display) |
| Threads | 2 | 1 | 1 | 1 | 5 |
| Factory | 5 | 0 | 0 | 0 | 5 |
| Execution | 0 | 0 | 0 | 0 | 1 (display) |
| Traces | 1 | 1 | 0 | 2+ | 4+ |
| Audit | 0 | 0 | 0 | 0 | 1 (display) |
| Metrics | 0 | 0 | 0 | 0 | 1 (display) |
| Settings | 1 | 1 | 0 | 0 | 2 |
| Workspaces | 2 | 2 | 1 | 0 | 5 |
| Vault | 0 | 0 | 0 | 0 | 1 (display) |
| Watchers | 1 | 1 | 0 | 0 | 2 |
| Error Policy | 3 | 1 | 0 | 0 | 4 |
| Capabilities | 0 | 0 | 0 | 0 | 1 (display) |
| Solutions | 5 | 0 | 0 | 0 | 5 |
| Template Lib | 2 | 1 | 0 | 10+ | 13+ |
| Marketplace | 0 | 0 | 0 | 0 | 1 (display) |
| Guide | 0 | 0 | 0 | 15+ | 15+ (TOC) |
| Glossary | 0 | 0 | 0 | 0 | 22 terms |
| Onboarding | 4 | 3 | 0 | 0 | 7 |
| Agent Detail | 4 | 0 | 0 | 2 | 6 |
| Agent Chat | 1 | 1 | 0 | 1 | 3 |

Total interactive elements to test across 33 pages: ~150+
