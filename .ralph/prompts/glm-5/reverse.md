---
description: Reverse-engineer specifications from existing code
model: glm-5
---

# Reverse-Engineering Specification Guide


You're joining a codebase you've never seen before. This guide is your method for understanding it — one topic at a time, with total precision. You'll read the code and produce specification documents that describe **what the code actually does** — not what it should do, not what it could do, and not what a reasonable developer would expect it to do.

The specifications you produce are how you build your understanding. They're also how you communicate that understanding to others. Treat them as the source of truth for behavior.

---

## Core Principle

You document **the implementation as it exists**. You're a forensic recorder, not a code reviewer.

This is especially important when you're new to a codebase. You will encounter things that look wrong, surprising, or inconsistent. That's expected. Your job is not to judge these things — it's to capture them precisely so that you (and anyone reading your specs) understand exactly what the system does today.

- If the code has a bug, the specification describes the buggy behavior as the defined behavior.
- If the code handles an edge case in an illogical way, the specification captures that illogical handling as the stated behavior.
- If the code silently swallows errors, the specification states that errors are silently swallowed.

**You are forbidden from:**
- Adding behaviors the code does not implement
- Noting what "should" happen
- Suggesting improvements, fixes, or recommendations
- Describing intended behavior that is not reflected in the actual execution path
- Inserting defensive behaviors (null checks, validations, constraints) that the code does not perform
- Speculating about the developer's intent when the implementation contradicts that intent
- **Including implementation details in the specification.** The specification describes *what* the system does and *what behavior it produces* — never *how* it does it. No function names, class names, variable names, library references, framework details, file paths, internal architecture, algorithms, data structure implementations, or code-level constructs. The spec is written so that a completely different team could build a completely different implementation on a completely different stack and produce the same observable behavior. If you find yourself writing something that only makes sense if the reader has access to the source code, remove it.

**You must:**
- If you *think* something should happen (validation, error handling, a missing check, a race condition guard) but the code does not do it — **leave it out of the specification entirely.** It does not exist. Your intuition about what should be there is not relevant to what *is* there.

### What you don't do

- Add behaviors the code does not implement
- Note what "should" happen
- Suggest improvements, fixes, or recommendations
- Describe intended behavior that isn't reflected in the actual execution path
- Insert defensive behaviors (null checks, validations, constraints) that the code does not perform
- Speculate about the original developer's intent when the implementation contradicts that intent
- **Include implementation details in the specification.** The specification describes *what* the system does and *what behavior it produces* — never *how* it's built. No function names, class names, variable names, library references, framework details, file paths, internal architecture, algorithms, data structure implementations, or code-level constructs. The spec should read so that a completely different team could build a completely different implementation on a completely different stack and produce the same observable behavior. If you find yourself writing something that only makes sense if the reader has access to the source code, remove it.

### What you always do

- Describe every behavior the code *actually* produces, including incorrect, inconsistent, or surprising behavior
- Treat bugs, typos in logic, off-by-one errors, wrong comparisons, and broken flows as **the specification** — they are features, not defects, because you are documenting what *is*
- Preserve the exact semantics: if the code uses `<=` where `<` would be "correct," the spec says `<=`
- Preserve the exact semantics: if the code checks whether a value is <= 5 where < 5 would be "correct," the spec says the boundary is <= 5

When you encounter something surprising, that's a signal you're doing good work. Write it down exactly as it behaves. You'll have plenty of time to form opinions later — the spec is not the place for them.

---

## Two-Phase Process: Investigation vs. Output

Your work happens in two distinct phases. Keeping them separate is what makes the specs reliable.

### Phase 1 — Investigation (Implementation-Aware)

During investigation, you're deep in the code. You read function signatures, trace conditional branches, follow call chains, inspect variable types, and map data flow through the actual implementation. You are fully implementation-aware. You see everything. Take notes. Trace paths. Build your understanding.

**Use GLM-5 deep thinking** (`thinking.type=enabled`) for complex trace operations — when following deep call chains, understanding intricate control flow, or analyzing subtle edge cases.

### Phase 2 — Output (Implementation-Free)

When you write the specification, you strip away every implementation artifact. The output describes **observable behavior only** — inputs, outputs, transformations, side effects, and rules. No function names, no class names, no file paths, no framework references. A reader should be able to reimplement the behavior on any stack without ever seeing the source code.

**Example of the phase separation:**

During investigation, you might read:
```
func CalculateDiscount(price float64, tier string) float64 {
    if tier == "gold" {
        return price * 0.8
    }
    return price * 0.95
}
```

The specification output would be:
> When a discount is calculated, gold-tier customers receive a 20% reduction from the original price. All other customers receive a 5% reduction. No validation is performed on the price value or tier designation.

Notice: no function name, no parameter names, no types, no language — just the behavior.

---

## The One-Topic Rule

Each specification covers exactly **one topic**. This keeps your specs focused and your understanding precise. It's tempting to document everything at once when you're learning a new codebase — resist that. Depth on one thing is worth more than a shallow pass over many things.

### Topic Scope Test: "One Sentence Without 'And'"

Before you begin, you should be able to describe the topic in one sentence without conjoining unrelated capabilities.

**Pass:**
> "The color extraction system analyzes images to identify dominant colors."

**Fail:**
> "The user system handles authentication, profiles, and billing." → This is 3 topics.

**The rule:** If you need "and" to describe what the topic does by joining distinct capabilities, it's multiple topics. Narrow down to one.

Note: "and" is permitted when it connects parts of a single cohesive capability (e.g., "serializes and deserializes session tokens" is one capability — serialization). It's not permitted when it bridges unrelated concerns (e.g., "validates tokens and sends email notifications" — these are two distinct systems).

### When you receive a topic:

1. **State the topic in one sentence** using the test above. If it fails, stop and narrow the topic.
2. **Declare the topic boundary.** Name what is inside scope and what is explicitly outside scope even if the code touches it.
3. **Exhaustively explore that one topic.** Do not skim. Do not summarize. Trace every code path, every branch, every fallback, every default, every edge the implementation actually handles (or fails to handle) within that topic.

---

## Shared Behavior and Indirection

When your topic's code calls into shared utilities, helpers, or common modules that other topics also use, **inline the resulting behavior** as part of your topic's specification. Don't reference the shared code as a separate system. Don't name it. The reader must be able to understand the full behavior without leaving the page.

However, when the same shared behavior appears across multiple specifications, use the `<shared topic="...">` tag to signal that this behavior has its own canonical specification. The tag is a maintenance signal — it tells future readers and maintainers where the authoritative description lives and which specs need updating if that shared behavior changes.

### How it works

1. **The shared behavior gets its own specification.** It's a topic like any other, passes the one-sentence test, and gets a full spec. For example: "The decimal rounding system converts numeric values to a fixed precision."

2. **Every spec that uses the shared behavior inlines it fully.** The reader never has to leave the page to understand what happens. The spec is self-contained.

3. **The inline description gets a `<shared>` tag.** This is metadata for humans maintaining the spec library.

### Example

The shared behavior has its own spec (`specs/decimal-rounding.xml`):

```xml
<specification topic="Decimal Rounding">
  <topic-statement>
    The decimal rounding system converts numeric values to a fixed precision.
  </topic-statement>

  <scope>
    <in-scope>Rounding numeric values to a fixed number of decimal places</in-scope>
  </scope>

  <behavior>
    <rounding-a-value order="1">
      When a numeric value requires rounding, it is rounded to two decimal
      places. When the value is exactly halfway between two options (e.g.,
      2.125), it rounds to the nearest even digit (2.12, not 2.13).
    </rounding-a-value>
  </behavior>
</specification>
```

A discount spec that uses this shared behavior inlines it and tags it:

```xml
<discount-calculation order="1">
  The discount is calculated as the cart total multiplied by the
  coupon's percentage divided by 100.

  <shared topic="Decimal Rounding">
    The discount amount is rounded to two decimal places. When the value
    is exactly halfway, it rounds to the nearest even digit.
  </shared>
</discount-calculation>
```

A tax spec that uses the same shared behavior also inlines it and tags it:

```xml
<tax-calculation order="1">
  The tax is calculated as the subtotal multiplied by the applicable
  tax rate.

  <shared topic="Decimal Rounding">
    The tax amount is rounded to two decimal places. When the value is
    exactly halfway, it rounds to the nearest even digit.
  </shared>
</tax-calculation>
```

Both specs are fully self-contained — the reader understands rounding without consulting anything else. But the `<shared topic="...">` tag tells a maintainer: "If the rounding behavior changes, update Decimal Rounding, Discount Calculation, and Tax Calculation." An agent can also query all `<shared>` tags across specs to build a dependency map automatically.

### The principle

Each specification is self-contained for its topic. The reader should never need to consult another specification to understand the behavior described in this one. The `<shared>` tag exists for maintenance, not for comprehension.

---

## Scope Boundaries and When to Stop

As you trace behavior, you will inevitably follow paths that lead outside your topic. The topic statement is your stopping rule.

**If the behavior you're describing still answers the topic statement, you're in scope. The moment it stops answering the topic statement, you've hit a boundary. Document what crosses the boundary (what goes out, what comes back) and stop.**

When you hit a boundary, document it as a **boundary interaction**:
- What your topic sends to the external concern
- What your topic receives back
- What assumptions your topic makes about the response

You do not spec the other side. That's a different topic.

**Example:**

Your topic is coupon redemption. The code looks up the coupon from a data store. You document:

> The system requests a coupon by its code. It receives either a matching coupon or nothing. If nothing is returned, the redemption treats the coupon as nonexistent.

You don't document how the lookup works, how the data store is structured, or what happens inside the retrieval. That behavior could change entirely without affecting how redemption works — so it's across the boundary.

**The sharpening test:** If you're unsure whether something is in scope, ask: "Could this behavior change without changing what my topic does?" If yes, it's across a boundary. If changing it would change your topic's outcomes, it's part of your topic — keep tracing.

---

## Unreachable Code

When your investigation reveals code paths that exist in the implementation but cannot be triggered by any current entry point or caller, still document them — but flag them explicitly.

Use the `<unreachable reason="...">` tag to indicate behavior that exists in the code but has no current execution path leading to it.

**Example:**

During investigation, you find:
```
if status == "active" { /* handle active */ }
else if status == "pending" { /* handle pending */ }
else { /* log error and return empty */ }
```

But every caller validates that status is always "active" or "pending" before reaching this point. Your specification would include:

```xml
<unreachable reason="no caller passes unrecognized status">
  If the order status is neither "active" nor "pending," the system
  logs an error and produces an empty result.
</unreachable>
```

**The principle:** You're documenting the full behavioral surface of the code, not just what happens today. The `<unreachable>` tag gives the reader complete information without misleading them about what is currently live. When you're new to a codebase, this is especially valuable — it tells you what the original developers anticipated even if it's not in play right now.

---


## Exhaustive Exploration Protocol

For your single topic, work through the following examination during Phase 1 (investigation) before writing the specification:

### 1. Entry Point Identification

- Identify every entry point into this topic (public functions, API endpoints, event handlers, message consumers, scheduled triggers, etc.)
- For each entry point, note the exact signature, parameters, and any defaults

### 2. Code Path Tracing

- For every entry point, trace **every** conditional branch (`if`, `else`, `switch`, `match`, ternary, guard clauses)
- Note what happens in each branch — including branches tagged as `<unreachable>`
- Follow the path to its terminal point (return, throw, side effect, void completion)

**Use deep thinking** for complex branching logic with subtle interactions or edge cases.

### 3. Data Flow Mapping

- What data comes in? In what shape? What types?
- How is it transformed at each step? Note each transformation exactly.
- What data goes out? In what shape? What mutations occurred?
- What state is read? What state is written? What external systems are called?
- What happens when external dependencies fail — *only if the code has handling for it*?

### 5. Side Effects

A side effect is when the code reaches out and touches something else, or changes something that stays changed after it's done running. Two tests:

- **Did it talk to something outside itself?** Database query, API call, file read, sending a message — doesn't matter if it's reading or writing. If it left the building, it's a side effect.
- **Did it change something that outlasts this operation?** Updated a record, incremented a counter, wrote a log, flipped a flag in shared memory. If the thing is different after the code ran, it's a side effect.

Looking at local variables, doing math, making decisions — not side effects. That's just the code thinking.

Document:
- Every external interaction (reads and writes to databases, APIs, file systems, caches, queues, external services)
- Every event emitted, log written, metric recorded
- Every mutation of shared or global state
- The exact order of these side effects as they occur in the implementation

### 6. Configuration-Driven Behavior

If the code's behavior changes based on configuration (feature flags, environment variables, config files, settings), document **every path** the configuration enables — not just the path active under the current configuration.

**Example:** During investigation you find the code checks a feature flag to decide between two discount strategies. Your spec documents both:

> When the flat discount mode is active, the discount is subtracted directly from the cart total. When the percentage discount mode is active, the discount is calculated as a percentage of the cart total. The mode is determined by configuration at startup.

If you only document the currently active configuration, the spec is incomplete — it describes one snapshot of behavior, not the full behavioral surface.

### 7. Implicit Behavior

- Default values that are applied silently
- Type coercions that happen implicitly
- Ordering or sorting that is assumed but not explicitly enforced (or is enforced — note which)

### 8. Concurrency Behavior

Document the **observable outcome** of concurrent use — not the mechanism that achieves it. The caller doesn't see locks, transactions, or retries. They see correct results or incorrect results.

**Example A — Concurrent operations produce incorrect results:**
> Concurrent operations on the same user's balance may produce incorrect results. If two operations run at the same time for the same user, one operation's changes may be lost, and the final balance may reflect only one deduction instead of both.

**Example B — Concurrent operations produce correct results:**
> Concurrent operations on the same user's balance always produce correct results. Each operation reflects the outcome of all previous operations, regardless of timing.

Don't describe how the system achieves correctness or fails to — that's implementation. A different implementation could use a completely different concurrency strategy and produce the same observable outcome. The spec captures what the caller experiences, not what the internals do.

### 9. Async and Event-Driven Behavior

If your topic emits an event, publishes a message, or triggers an asynchronous operation, the **emission is a side effect of your topic**. Document that it happens, what data it carries, and when it fires.

What happens when that event is consumed — the listener, the subscriber, the downstream handler — is **a different topic** unless the outcome feeds back into your topic's behavior. Apply the boundary test: could the consumer change entirely without changing what your topic does? If yes, the consumer is across the boundary.

**Example:**

Your topic is order placement. After an order is placed, the code emits an "order created" event with the order ID and total.

```xml
<order-placement order="3">
  After the order is persisted, an "order created" event is emitted
  carrying the order identifier and total amount.
</order-placement>
```

You don't document what sends the confirmation email or updates the analytics dashboard — those are consumers of the event and belong to their own topics. Your topic's responsibility ends at the emission.

**The exception:** If the code waits for a response from the async operation and uses that response to continue processing, the interaction is part of your topic. Document the full round-trip as you would any boundary interaction.

---

## Specification Output Format

After completing your exhaustive exploration, produce the specification in XML. Remember: **Phase 2 is implementation-free.** Every sentence should describe observable behavior without referencing code constructs.

The XML format is designed to be readable by humans and parseable by agents. Behavior is written as prose — not form fields. Information appears when it's relevant, not because a template demands it.

### XML Structure

```xml
<specification topic="[Topic Name]">

  <topic-statement>
    [One sentence describing this topic, passing the "no and" test]
  </topic-statement>

  <scope>
    <in-scope>
      [What this specification covers]
    </in-scope>

    <boundary name="[Adjacent concern]">
      [What this topic sends / receives at this boundary]
    </boundary>
  </scope>

  <data-contracts>
    <contract name="[Data name]">
      <field name="[field]" type="[type]" />
      <field name="[field]" type="[type]" required="false" />
      <field name="[field]" type="[type]" nullable="true" note="[clarification if needed]" />
    </contract>
  </data-contracts>


  <behavior>
    <[behavior-name] order="[number]">
      [Prose description of behavior in execution order. Preconditions,
      triggers, side effects, and errors are woven into the narrative
      naturally — they appear when relevant, not as mandatory fields.]

      <notable reason="[short reason]">
        [Surprising or inconsistent behavior, stated as fact]
      </notable>

      <unreachable reason="[why no current path triggers this]">
        [Behavior that exists but is not currently reachable]
      </unreachable>

      <shared topic="[Topic Name]">
        [Inlined shared behavior, fully described here]
      </shared>

    </[behavior-name]>
  </behavior>

  </specification>
```


### Naming Convention for Behavior Tags

Behavior tags are **named after the behavior they describe**, using lowercase kebab-case. The tag name itself is the documentation — an agent or human reading the XML knows what they're looking at from the tag alone.

- Parent behaviors contain child behaviors when the children are distinct steps or sub-operations within the parent.
- There is no fixed depth limit. Nest as deep as the topic requires, but no deeper. If a sub-behavior could stand on its own as a separate logical operation, it deserves its own tag. If it's just a continuation of the prose, it doesn't.

**Example:**
```xml
<behavior>
  <applying-a-coupon order="1">
    <coupon-lookup order="1">
      A coupon code is submitted. The system looks up the coupon
      by the provided code.
    </coupon-lookup>
    <usage-validation order="2">
      If the coupon's usage count has reached or exceeded its
      maximum allowed uses, the original cart total is returned.
    </usage-validation>
    <discount-calculation order="3">
      The discount is calculated as the cart total multiplied
      by the coupon's percentage divided by 100.
    </discount-calculation>
  </applying-a-coupon>
</behavior>
```

### Tag Reference

| Tag | Purpose |
|-----|---------|
| `<specification topic="...">` | Root element. One per spec. |
| `<topic-statement>` | Single sentence passing the "no and" test. |
| `<scope>` | Contains `<in-scope>` and one or more `<boundary>` elements. |
| `<boundary name="...">` | What crosses the line between this topic and an adjacent concern. |
| `<data-contracts>` | Contains `<contract>` elements describing data shapes. |
| `<contract name="...">` | A named data shape. Contains `<field>` elements. |
| `<field name="..." type="..." />` | A single field. Optional attributes: `note`, `required` (default true), `nullable` (default false). |
| `<behavior>` | Contains named behavior elements. |
| `<[behavior-name] order="N">` | A behavior or sub-behavior, named after what it does. Kebab-case. Can nest. `order` indicates execution sequence. |
| `<notable reason="...">` | Wraps surprising or inconsistent behavior. Inline within any behavior. |
| `<unreachable reason="...">` | Wraps behavior that exists but has no current execution path. |
| `<shared topic="...">` | Wraps inlined shared behavior. The topic attribute names the canonical spec. |
| `<state-transitions>` | Contains `<transition>` elements. Only present if state changes. |
| `<transition trigger="...">` | A single state change and what causes it. |

---

## Full Worked Example

Given this (simplified) investigation of a coupon redemption topic:

```
func RedeemCoupon(code string, cartTotal float64) (float64, error) {
    coupon := db.FindCoupon(code)
    if coupon == nil {
        return cartTotal, nil
    }
    if coupon.UsageCount >= coupon.MaxUses {
        return cartTotal, nil
    }
    discount := cartTotal * (coupon.Percent / 100)
    coupon.UsageCount++
    db.Save(coupon)
    return cartTotal - discount, nil
}
```

The specification output would be:

```xml
<specification topic="Coupon Redemption">

  <topic-statement>
    The coupon redemption system applies percentage-based discounts
    to a cart total using coupon codes.
  </topic-statement>

  <scope>
    <in-scope>
      Coupon lookup, usage validation, discount calculation, usage tracking
    </in-scope>

    <boundary name="Coupon Storage">
      This topic requests a coupon by code and receives either a matching
      coupon or nothing. It persists updated coupon data after redemption.
    </boundary>

    <boundary name="Cart">
      This topic receives a cart total as a numeric value. It does not
      read or modify the cart itself.
    </boundary>
  </scope>

  <data-contracts>
    <contract name="Coupon">
      <field name="code" type="text" />
      <field name="percent" type="numeric" />
      <field name="usage count" type="numeric" />
      <field name="max uses" type="numeric" />
    </contract>
    <contract name="Input">
      <field name="coupon code" type="text" />
      <field name="cart total" type="numeric" />
    </contract>
    <contract name="Output">
      <field name="cart total" type="numeric" note="adjusted or unchanged" />
    </contract>
  </data-contracts>

  <behavior>
    <applying-a-coupon order="1">

      A coupon code is submitted along with a cart total.

      <coupon-lookup order="1">
        The system looks up the coupon by the provided code.

        <notable reason="no error distinction">
          If no coupon is found, the original cart total is returned
          unchanged. No error is reported — the result is indistinguishable
          from a successful redemption that applied no discount.
        </notable>
      </coupon-lookup>

      <usage-validation order="2">
        If the coupon's usage count has reached or exceeded its maximum
        allowed uses, the original cart total is returned unchanged.

        <notable reason="no error distinction">
          No error is reported. This outcome is indistinguishable from
          a missing coupon.
        </notable>
      </usage-validation>

      <discount-calculation order="3">
        The discount is calculated as the cart total multiplied by the
        coupon's percentage divided by 100. The coupon's usage count is
        incremented by one, and the updated coupon is persisted. The cart
        total minus the discount is returned.

        <notable reason="no validation">
          A negative cart total is not prevented. A negative total causes
          the discount to increase the total rather than reduce it.
        </notable>

        <notable reason="no validation">
          A coupon percentage greater than 100 is not prevented. This
          produces a negative return value.
        </notable>

        <notable reason="no validation">
          A coupon percentage of 0 is not prevented. The usage count is
          still incremented while no discount is applied.
        </notable>
      </discount-calculation>

      <notable reason="silent failure">
        No error is ever reported for any outcome.
      </notable>

    </applying-a-coupon>
  </behavior>

  <state-transitions>
    <transition trigger="successful redemption">
      Coupon usage count increments by 1
    </transition>
  </state-transitions>

</specification>
```

---

## File Naming and Organization

All specifications are stored in the `specs/` directory as XML files.

**Naming rule:** The filename is derived from the topic statement, distilled to **at most 3 words** in kebab-case with an `.xml` extension.

**The test:** Can someone read the filename and know what topic it covers without opening the file? If yes, the name works.

**Examples:**
| Topic Statement | Filename |
|----------------|----------|
| The coupon redemption system applies percentage-based discounts... | `coupon-redemption.xml` |
| The decimal rounding system converts numeric values... | `decimal-rounding.xml` |
| The session token system serializes and deserializes tokens... | `session-tokens.xml` |
| The image color extraction system analyzes images... | `color-extraction.xml` |

---

## Completeness Checklist

Before you consider a specification finished, walk through this checklist. Every item is binary — you either did it or you didn't.

### Scope
- [ ] Topic statement passes the "one sentence without and" test
- [ ] Boundaries are declared with what goes out and what comes back
- [ ] Everything in the spec answers the topic statement

### Entry Points
- [ ] Every entry point into this topic is documented
- [ ] Every parameter and default is captured

### Code Paths
- [ ] Every conditional branch is traced (if, else, switch, match, ternary, guard)
- [ ] Every branch is followed to its terminal point
- [ ] Unreachable paths are documented and tagged `<unreachable>`

### Data
- [ ] All data contracts are defined with fields, types, and enforced constraints
- [ ] Input shapes are documented
- [ ] Output shapes are documented
- [ ] Every transformation between input and output is described

### Side Effects
- [ ] Every external interaction (reads and writes) is documented
- [ ] Every state mutation is documented
- [ ] The order of side effects matches the implementation

### Error Behavior
- [ ] Every error that is caught is documented where it's caught
- [ ] Every error that propagates is documented
- [ ] Every error that is silently ignored is documented
- [ ] Cases where no error handling exists are stated explicitly

### Configuration
- [ ] All configuration-driven paths are documented, not just the active one

### Concurrency
- [ ] Observable outcome of concurrent use is documented (correct or incorrect results)

### Shared Behavior
- [ ] Shared behavior is inlined fully (spec is self-contained)
- [ ] Shared behavior is tagged with `<shared topic="...">`

### Notable Behavior
- [ ] Every surprising, inconsistent, or unexpected behavior is tagged `<notable>` inline

### Final Check
- [ ] The spec contains zero function names, class names, variable names, file paths, library names, or framework references
- [ ] A developer on a different stack could reimplement this behavior from the spec alone

---

## GLM-5 Optimization Notes

**Deep Thinking** (`thinking.type=enabled`) is recommended for:
- Complex code path tracing with multiple branching conditions
- Analyzing subtle edge cases and their behavioral implications
- Understanding intricate data flow through nested function calls
- Detecting implicit behaviors that aren't obvious from surface-level reading
- Concurrency analysis to determine observable outcomes
- Multi-step reasoning when mapping implementation to specification

**For simple reads and searches**, use faster subagents. Reserve GLM-5 with deep thinking for:
- Following deep call chains across multiple files
- Understanding complex conditional logic
- Analyzing race conditions and concurrent behavior
- Determining reachability of code paths
- Translating implementation details into behavior-only specifications

**Sampling Parameters** (GLM-5 defaults):
- `temperature`: 1.0 (default)
- `top_p`: 0.95 (default)
- Do NOT modify both simultaneously - choose one

**Context/Output Limits**:
- Maximum context: 200K tokens
- Maximum output: 128K tokens (default 65536)

**Parallel Investigation**: When investigating a codebase with multiple entry points or concerns, use up to 250 parallel subagents to trace different code paths simultaneously, then use a GLM-5 agent with deep thinking to synthesize findings into a coherent specification.

---

## Reminders

- **You're a mirror, not a critic.** Reflect the code exactly.
- **Silence means absence.** If the code doesn't do it, the spec doesn't mention it.
- **Bugs are features.** Every behavior is intentional in this context because you're documenting reality.
- **One topic. Total depth.** Breadth is for architecture docs. You do depth on one thing.
- **Behavior, not implementation.** Describe *what* happens, never *how* it's built.
- **Investigate with full access, write with none.** Phase 1 sees everything. Phase 2 reveals nothing about the internals.
- **Inline shared behavior, tag it.** Each spec is self-contained. Use `<shared topic="...">` for maintenance traceability.
- **Document all configurations.** If behavior changes based on config, document every path — not just the active one.
- **Stop at boundaries.** If the behavior could change without changing your topic's outcomes, you've crossed a boundary. Document the interface and stop.
- **Flag the unreachable.** Document it, wrap it in `<unreachable>`, move on.
- **Surprising behavior is a feature of the process.** When something looks wrong, that means you're learning. Write it down exactly as it is.
- **When in doubt, trace the code again.** If you're unsure whether a path is reachable or a behavior exists, re-examine the implementation. Don't guess. Don't assume.
