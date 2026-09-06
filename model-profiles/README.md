# Model profiles: the catalog, and nothing else

This directory holds the versioned, provider-neutral, credential-free **catalog** of model
destinations: declarative documents conforming to the shared `model-profile` contract. It is the
same class of thing as `repo-registry/` and `contracts/`, which is why it can live in the harness
at all.

## Why this is defensible against the rule directly above it

`CLAUDE.md` says the harness carries no doctrine, agents, skills, tools, runtime state, metrics or
data, and that if a file answers a question about a brain's content it belongs in that brain. A
model-profile directory survives that sentence only under a narrow reading, and the reading was
ruled on rather than assumed:

> `H/model-profiles/**` may hold only the versioned, provider-neutral, credential-free profile
> catalog (declarative documents conforming to C01's `model-profile` schema), which is the same
> class of thing as the harness's registry and contracts; every runtime instance, endpoint state,
> quota observation and route receipt lives in R. **If a profile needs runtime state it is in the
> wrong repo.**

So the split is:

| Lives here (H) | Lives in the runtime (R) |
|---|---|
| That a destination exists, and its declared identity | Where it actually is: host, URL, port, container |
| Which data classes it is permitted to receive | Whether it answered just now |
| Its declared allowance shape and billing mode | How much allowance is left, and when that was read |
| Which task classes it declares, and whether quality was measured | The measurement run itself, and its receipts |
| Which destinations it may explicitly fall back to | Which one was chosen for a given task, and why |

A document here is a claim about permission and shape. Everything about *right now* is an
observation, and an observation has a source and a timestamp, neither of which a versioned file
can honestly carry.

## The rule that is easy to miss

**`availability.state` is always `unknown` in this directory.** The contract requires the field and
it is, by its nature, runtime state: it answers "did the host respond". A versioned document
cannot know that, and one that claimed to would be asserting a fact about a machine it has never
contacted. The runtime overlays a real reading at use time.

That is also fail-closed by construction rather than by good intentions: `unknown` availability
refuses in the runtime's eligibility screen, so a destination read only out of this catalog is
never dispatched until something actually looked at the host.

## The five fields, and why they are five

Every document states placement, capability, auth mode, billing and execution surface separately.
They are five independent facts and collapsing them into one tier label is the defect the whole
packet exists to prevent:

- **Local is a location, not a privacy promise.** A local process that forwards is not private, and
  an endpoint's software name is not proof of where it runs or who controls it.
- **A tier name is not a measurement.** `quality_evidence.status` is `unmeasured` until an
  evaluation has actually run and named its evidence. No suitability follows from placement.
- **A subscription seat is not an execution surface.** How access is paid for and how the call is
  made are different questions with different answers.
- **Unknown quota is not unlimited.** A profile with an unknown allowance says so, and the runtime
  refuses to turn that into a number.

## Credentials

**No document here contains a credential value, under any key.** Authentication is carried as a
reference: an id plus the backend that holds it. A native provider session is never referenced at
all, because it belongs to the person who logged in and there is nothing here that should be
tempted to use it.

## Checking it

The guard lives in the runtime, not here, because this directory may hold only declarative
documents:

```
python3 -m adapter.model_providers.catalog --audit <path-to-this-directory>/profiles
python3 -m adapter.model_providers.catalog --load  <path-to-this-directory>/profiles
```

The audit fails on an endpoint, a capacity figure, a live allowance reading, a declared
availability, or anything credential-shaped. It is exercised against planted defects in
`adapter/model_providers/test_model_providers.py`, so it is a check that has been watched failing
rather than one that has only ever been green.

## Status

Contract: `model-profile` at `0.1.0-draft.6`, digest
`sha256:224cd1c3dcfae0d959d667114cf8aa15ed245ca366e68866c79540b878650fb5`. **Draft, not pinned**;
expect a reconciliation delta when the contract pins.

The four documents in `profiles/` are **shape examples covering the four combinations the runtime
must tell apart**, not a recommended deployment and not an endorsement of any product. No model
named here is installed, downloaded, logged into or called by anything in this repository.
