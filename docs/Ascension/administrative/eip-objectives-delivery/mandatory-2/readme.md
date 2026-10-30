---
id: 40201d24-0cc9-4204-9c42-77b9bcc309ee
---

# Structure, document and make your technical architecture reliable

:::subpages

## Extracted from the official PDF

This objective asks you to produce a project that stands up without you: an architecture you can defend, a pipeline that checks the code on every change, tests that actually catch regressions, a deployment someone else can reproduce, and a written trace of the decisions you made.

### Design and document your architecture

- An architecture diagram showing: the components and services, what each is responsible for, the dependencies between them, the data flows and their direction, the external dependencies, and the deployment boundaries.
- A data diagram: main entities, relationships, expected volumes.
- Points of failure identified: what happens if a component goes down, if an external service stops responding, if the load doubles.
- Justification of your structuring choices, and for each one, the alternative you considered and set aside, with the reason.
- The diagram is kept up to date. A diagram that no longer matches the code in May is worth nothing.

### Keep a record of technical decisions (ADR: Architecture Decision Record)

One entry per structuring decision, written at the moment it is made, in a consistent format:

- Date
- Context and problem
- Options considered
- Option chosen
- Reason
- Consequences accepted

What it is for: it carries the trace of the reasoning, not just the result.

- At least 4 decisions recorded over the year.
- They are about things that commit the project: choice of technology, how components are split, data model, exchange format, authentication strategy, deployment mode, concurrency handling, dropping a component.
- At least 2 options genuinely weighed per decision.
- Consequences spelled out: what the decision costs in dependency, complexity, performance, or debt taken on.
- At least one decision you went back on during the year, with what changed your mind.

### Produce your technical documentation

- **README:** what the project is for, prerequisites, installation, configuration, environment variables, main commands, folder structure, how to run the tests.
- **API documentation:** endpoints exposed, expected parameters, response formats, error codes, example calls.
- **Operations documentation:** where the logs are, how to restart, what to do when something common breaks.

### Set up a continuous integration pipeline

- Automatic execution on every commit or merge request: static analysis, formatting, tests, build.
- A browsable history over the whole period, showing both successful and failed runs.
- Merges blocked on failure on the main branch.
- At least one documented case where the pipeline stopped a broken change before it reached the main branch.

### Measure your code quality

- Analysis tools configured and run in the pipeline: linting, formatting, static analysis, type checking where your language allows it.
- A baseline and a final measurement: number of warnings and errors at the start, at the end, and what you fixed in between.
- The rules you adopted, and the ones you deliberately disabled, with the reason for each exception.
- Technical debt logged: what you know you should fix, why you haven't, and roughly what it would cost.

### Test

- The critical path identified: the flows or functions whose failure makes the product unusable.
- Automated tests on that critical path, run in the pipeline.
- Coverage figure recorded and presented, with the share corresponding to the critical path.
- At least one integration test covering a full flow, not an isolated function.
- At least 3 regressions caught by your tests, documented: what broke, which test caught it, when. A test that has never caught anything proves nothing; a test that stopped a broken release proves everything.
- Behavior on error: the failure cases you anticipated, what the system does in each, what gets logged.

### Review each other's code

- No merge to the main branch without review by another team member.
- Evidence of the review: comments, change requests, discussion. Approving without a single comment is not a review.
- At least 15 merge requests reviewed over the year, spread across the team.
- At least 3 cases where a review led to a change before merging, presented.

### Make your deployment reproducible

- The project must be installable and runnable by someone outside the team.
- An automated procedure where possible: containerization, install script, composition file.
- A reproducibility test carried out and dated, by someone outside the team. Record how long it took, where they got stuck, and what you had to fix in the documentation as a result.
- Configuration kept out of the code: environment variables, no secrets in the repository.

### Timeline and deliverables

| Item | Due | Deliverable |
| --- | --- | --- |
| Architecture | First version before end of November, updated at every structuring change | Architecture diagram and data diagram, up to date |
| Decision record | Fed October to May, 4 decisions minimum | Complete dated record |
| Technical documentation | First version before end of December, corrected after the reproducibility test | README, API and operations documentation |
| Pipeline | Running before end of December | Link to the run history |
| Code quality | Baseline in December, final measurement in May | Initial and final static analysis reports, debt log |
| Tests | Critical path covered before end of March | Coverage report, list of regressions caught |
| Code review | Throughout the year | Merge request history and review comments |
| Reproducibility test | Before end of March | Dated report: who, how long, blockers, fixes applied |

### What you submit

- Architecture diagram, up to date, and data diagram
- Complete dated record of technical decisions
- README, API documentation and operations documentation
- Link to the pipeline run history
- Initial and final static analysis reports
- Test coverage report
- List of regressions caught, with dates and the tests concerned
- Merge request history and review comments
- Reproducibility test report, with who, when, how long and the blockers
- Technical debt log
