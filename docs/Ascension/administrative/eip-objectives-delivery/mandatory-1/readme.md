---
id: 3853400b-40e1-41e7-84d8-571653e208ad
---

# Track what's out there and use it to crack your project's hard problem

:::subpages

## Extracted from the official PDF

This objective asks you to take up a stance of technical exploration and put it at the service of a real problem. Keeping up with your field is not a documentation exercise: it exists to find out how to solve what you cannot do yet.

The hard problem

Every project has one part harder than the rest: a computation that has to fit in a given time, a synchronization, a volume of data, a matching algorithm, a hardware constraint, a level of reliability to guarantee, a running cost to keep under control.

That is what your research, your experiments and your integration have to be about.

Characterize the hard problem

- A statement of the technical problem: what your project has to do and cannot do properly yet.
- What makes it hard: a constraint of time, volume, resources, precision, reliability, cost, or compatibility.
- What fails with a naive approach: what the obvious solution gives you, and why it is not enough. With a measurement to back it up, however rough.
- Success criteria in figures: above which threshold the problem counts as solved (a time, a rate, a capacity, a cost).

Set up how you keep up

- Sources followed, listed and justified: official documentation, scientific publications, engineering blogs, repositories and releases you track, newsletters, conferences, chat servers, specialist forums. For each one, what it brings and why you kept it.
- Tools and automations in place: a feed aggregator, alerts on repositories or topics, subscriptions, a team channel fed automatically, a shared note base. The setup has to be described and demonstrable, not just asserted.
- A rhythm defined and held: how often each member spends time on this, and how much.
- Split within the team: who follows which area. Research run by one person alone does not spread.
- A research log fed through the year: date, source, subject, what it changes or could change for the project, what you did about it or why you did nothing. An entry with no conclusion does not count.
- At least 20 entries over the year, spread out over time.

Share it and use it internally

- A sharing ritual in place from November: a dedicated slot in your team meeting, a dedicated channel, a periodic note. Format is up to you, monthly at minimum.
- At least 6 internal presentations over the year, recorded: who presented what, to whom, what was taken from it.
- At least 3 things from your research actually used in the project: a library adopted, a method taken up, a fix applied, a configuration reused from a repository, a practice integrated. For each, the original source and what it changed.

Establish the state of the art on the hard problem

- A list of the existing approaches to the problem you identified: libraries, algorithms, architectures, services, published methods.
- A comparison of at least 3 approaches on explicit criteria that matter for your project: performance, cost, maturity, integration complexity, dependencies, license, community, maintenance.
- Sources cited and dated. A comparison produced without opening the original documentation or running anything shows immediately.
- Working hypotheses: which approach you think is best at this stage, and why.

Experiment: 2 prototypes of different kinds

- **The decision prototype**, putting two approaches head to head to settle a choice:
  - Two candidate solutions implemented on the same use case, with the same data set or the same scenario.
  - The same protocol for both: same conditions, same measurements, same environment. That is what makes the comparison valid.
  - Measurements taken and presented side by side.
  - The code of both prototypes kept and accessible.
- **The exploration prototype**, testing a lead you found, with no decision attached:
  - A technology, method or architecture spotted during the year that the team does not master.
  - A hypothesis stated beforehand: what you are trying to find out.
  - The result obtained, including a negative one. A lead explored then dropped, with the reason, is a valid result and often more instructive than a success.

Decide

- A reasoned technical decision on how to handle the hard problem, based on the prototype measurements and not on a preference.
- The approaches you set aside, and the reason for each.
- The consequences you accept: what the chosen solution costs you (a dependency, complexity, a running cost, debt you take on).

Integrate for real

- The chosen solution integrated into the project, in production or on the main branch.
- Proof that it works: an identifiable commit or merge, a demonstration, tests covering the module concerned.
- A before and after measurement on the success criteria you set in October: is the threshold reached, and by how much you fall short if not.
- What the integration replaced, or made possible that could not be done before.
- Architecture and documentation updated to reflect the change.
- Limits acknowledged: what is not solved, and under what conditions the solution would not hold.

Take part in technical communities

- Active participation in at least 2 technical communities related to your project's subjects: chat servers, specialist forums, repositories, mailing lists, professional groups.
- At least 5 public contributions recorded: a question asked with context and a reproduction, an answer given to someone else, a documented bug report, an experience shared, taking part in a technical discussion.
- At least one external contribution, however modest: a documentation fix, a detailed report, a proposed change, an answer that was accepted.
- For each contribution: the link, the date, the context, and what came out of it.

Timeline and deliverables

| Item | Due | Deliverable |
| --- | --- | --- |
| Characterizing the hard problem | Before end of October | Characterization note with success criteria in figures, validated by your mentor |
| Research setup | Described before end of October, held through May | Description of sources, tools, rhythm and split |
| Research log | Fed October to May, 20 entries minimum | Complete dated log |
| Internal sharing | Ritual in place from November, 6 presentations over the year | Records of the presentations, list of what was reused |
| State of the art | Before end of December | Comparison note on 3 approaches, sources cited and dated |
| Decision prototype | Before end of January | Code of both candidates, protocol, measurements side by side |
| Exploration prototype | Between February and April | Code, hypothesis stated beforehand, result including a negative one |
| Technical decision | Before end of February | Decision note, approaches set aside, consequences accepted |
| Integration | Before end of April | Commit or merge, demonstration, before/after measurement |
| Technical communities | November to May | Links and screenshots of the contributions, external contribution |

What you submit

- Characterization note on the hard problem, dated October, with the success criteria
- Description of your research setup: sources, tools, automations, rhythm, split
- Complete research log
- Records of the internal presentations
- State-of-the-art note with the comparison of approaches and sources cited
- Code and protocol of both prototypes, with the measurements taken
- Technical decision note
- Proof of integration: commit or merge, demonstration, tests
- Before and after measurements on the success criteria
- Links and screenshots of your contributions in the communities
