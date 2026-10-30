---
id: 1a61743d-78d9-4e2b-ab36-f07eefd19202
---

# Measure, test and optimize technical performance

:::subpages

## Extracted from the official PDF

This objective asks you to move out of "it works" and into "it holds up, and here is by how much". It is not about optimizing at random, but about following a complete chain: choose an axis, measure the starting state, diagnose where things block, change something precise, measure again, and observe a gap.

It is the only objective on this track whose result is a figure. That is also what makes it impossible to declare: either the measurement exists and the gap can be read, or nothing is demonstrated.

### Choose an axis

- One priority axis chosen from: response or execution time, memory or CPU consumption, behavior under load, client-side loading time, error rate and resilience, running cost, security.
- Justification of the choice: why this axis matters for your project specifically, and what happens if it is not dealt with.
- 2 to 3 measurable indicators defined, each with: its formula, the measurement tool, the conditions under which it is taken.
- A target figure set: what value you are aiming for by the end of the year, and what you base that figure on.

### Establish your measurement protocol

- A written protocol: hardware or environment, data set used, scenario run, number of repetitions, when the measurement is taken.
- Reproducibility: the protocol has to let someone else redo the same measurement and get a comparable result.
- Tooling in place for the axis you chose: instrumentation, logging, a profiler, a load testing tool, a dashboard, security analysis.
- Integrated into your development pipeline where possible: measurement run automatically, history kept, an alert on regression.

### Measure and diagnose

- A baseline measurement taken and dated on each indicator.
- A diagnosis: where the blockage is. Identified through your tooling (execution profile, slow queries, memory allocation, redundant calls, a vulnerable dependency) and not through intuition.
- An explanatory hypothesis: why this point blocks.
- An estimate of the gain expected if the hypothesis is right.

### Change something and measure again

- One precise, isolated change per loop: a query rewritten, caching added, an algorithm changed, a computation moved, a data structure modified, calls batched, a resource lightened, a security fix applied.
- Re-measurement under the exact conditions of the initial protocol.
- The gap observed, expressed in absolute value and in percentage.
- Conclusion: was the hypothesis right, is the gain up to what you expected.
- The trade-off you accept: what the optimization cost in readability, complexity, maintainability, or development time.
- A non-regression check after each loop: the existing tests still pass, and the other indicators on your axis have not been degraded by the optimization. Gaining on response time by doubling memory consumption is not a gain.
- Tracking the indicator over time: a history of the values taken, so you can tell a real gain from measurement noise.

### Timeline and deliverables

| Item | Due | Deliverable |
| --- | --- | --- |
| Axis and indicators chosen | Before end of December | Choice note, indicators with formula and tool, target figure |
| Measurement protocol | Before end of January | Written, reproducible protocol, tooling in place |
| Baseline and diagnosis | Before end of February | Dated records, diagnosis report, hypothesis stated |
| Loop 1 | Before end of March | Commit of the change, re-measurement, gap observed |
| Loop 2 | Before end of May | Commit of the change, re-measurement, gap observed |
| Non-regression | After each loop | Test results, indicator tracking history |

### What you submit

- Note on the axis chosen and the indicators defined
- Written measurement protocol
- Dated measurement records, initial and final, with screenshots or exports
- Profiling, load testing or analysis reports, depending on your axis
- Commits of the changes made
- Complete before / after table, including the changes that produced no gain
- Non-regression test results
- Indicator tracking history
