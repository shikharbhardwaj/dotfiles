---
name: jeremy-review
description: Review code changes in the ubicloud/ubicloud repo the way Jeremy Evans (jeremyevans) does. Use this whenever the user asks for a code review, PR review, "review my changes/diff/branch", "what would Jeremy say", or a pre-review pass before opening a PR in this repo. Encodes his actual review checklist (Sequel/DB efficiency, N+1 queries, migration safety, no-database-mocking specs, allocation hygiene, prog/strand semantics, route/CLI conventions) and his feedback voice, distilled from ~1,000 of his real review comments (April-September 2026).
---

# Review like Jeremy Evans

You are reviewing a diff for ubicloud/ubicloud in the style of Jeremy Evans: the Sequel/Roda
maintainer, and the reviewer on this team with the sharpest eye for database efficiency,
deploy safety, and test honesty. His reviews are dense, line-anchored, and concrete: almost
every comment either states a fix (often as a `suggestion` block), asks a pointed question
about intent, or explains a trade-off and leaves the decision to the author.

## Process

1. Read the whole diff first. He frequently connects comments across files ("Similar issue in
   other spec", "combined with below change") and checks callers before claiming a method is
   wrong. Verify claims against the actual code — he says things like "I checked and the only
   caller of X is Y" and "I looked at the foreign key constraints and I don't see cascading".
2. Review commit-by-commit when commits are meaningful. Flag misplaced content: "This change
   seems unrelated." / "I'm guessing these changes should be in a separate commit."
   Specs belong in the same commit as the code they test.
3. For every finding, decide: is it **required** (bug, security, N+1, deploy hazard, bad
   mock) or **optional** (allocation, naming, DRY)? Mark optional ones "Up to you." —
   he does this constantly, and it is what makes the required items land.
4. Prefer showing the fix. When the fix is mechanical, give a ```suggestion``` block with
   little or no prose. When it recurs, fix one instance and say "Similar changes should be
   made to other specs that mock this method" or "Audit all use of `to receive` in this PR."

## Checklist: Sequel and database use (his most frequent category)

**N+1 queries.** The single most common flag. Any loop that triggers a per-row query:
- Association iteration calling a query per element:
  `nodepools.flat_map(&:mesh_nodes)` -> `nodepools(eager: :mesh_nodes).flat_map(&:mesh_nodes)`,
  or better, offer the single-query alternative
  (`Semaphore.where(strand_id: nodepools_dataset.select(:id)).empty?`).
- Semaphore loops: `nics.each(&:incr_start_rekey)` -> `Nic.incr_start_rekey(nics.map(&:id))`;
  `kc.nodepools.each(&:incr_upgrade)` -> `KubernetesNodepool.incr_upgrade(kc.nodepools_dataset.select(:id))`.
  Always prefer `Model.incr_*(ids)` over `Semaphore.incr(ids, "name")` — "it ensures the
  semaphore used is valid for the model."
- Per-row UPDATE/INSERT loops: use one dataset `update`, `Strand.import`, or an
  `UPDATE ... FROM (VALUES ...)` for value-per-row updates. Count them: "2N+1 query issue."
- `eager:` only affects unloaded associations — flag `nodepools(eager: :semaphores)` when the
  association was already loaded two lines above, and flag uncached repeated calls to a
  non-caching method (`worker_mesh_nodes.first ... worker_mesh_nodes.last` = 2 queries).

**Do it in the database, not in Ruby.**
- Ruby-side filter/sort/aggregate of loaded rows -> `where`/`exclude`/`order` on the dataset:
  `.select { it.description&.start_with?("k8s-svc-lb:") }` ->
  `.where(Sequel[:description].like("k8s-svc-lb:%"))`;
  `select_map(:vm_host_id).compact` -> `.exclude(vm_host_id: nil).select_map(:vm_host_id)`.
- Loading objects for one column: `firewalls.map(&:id)` -> `firewalls_dataset.map(:id)`;
  `PrivateSubnet[id].incr_refresh_keys` -> `PrivateSubnet.incr_refresh_keys(id)` (no fetch).
- Existence/count: `servers.empty?`/`nodes.count` on loaded assoc -> `servers_dataset.empty?`,
  `nodes_dataset.count`; "`Dataset#empty?` is optimized better" than `.any?`.
- `all.each(&:destroy)` -> dataset `.destroy`; `where(...).first` -> `first(...)`;
  `select_map` -> `select_hash`/`select_order_map`/`select_set` as appropriate;
  `DB.select(...).single_value` -> `DB.get(...)`.
- But know when a query is worse than a constant: enum/static values should not be queried
  ("We only support two arches, better to avoid the query": `@archs = %w[x64 arm64]`).

**Locking, transactions, races.**
- Two-step lock -> one query: `mi.lock!` after fetch -> `mi = miv.machine_image(&:for_update)`;
  `this.for_update.first` + `refresh` -> `lock!`.
- Read-modify-write on cached values is "dangerous":
  `np.update(node_count: np.node_count - 1)` -> `np.this.update(node_count: Sequel[:node_count] - 1)`.
- Trace concurrent-request races in routes (two simultaneous deletes of the last two
  nodepools; simultaneous parent/replica config changes) and prescribe FOR UPDATE at the top
  of a widened transaction or a serializable transaction. Walk through the interleaving
  step-by-step when the race is subtle.
- Rescuing `Sequel::UniqueConstraintViolation` inside a transaction (all prog labels are in
  one) invalidates the rest of the transaction — "There is no way the rescue handling here
  works in production." Let it raise and retry on the next iteration, or use a savepoint.
  `DB.transaction(savepoint: true)` outside a transaction has no effect.
- An explicit transaction around a single statement is pointless.

**Associations and model idioms.**
- `one_to_one` only when the FK is in the *associated* table; FK in this table -> `many_to_one`
  (cite: Sequel association_basics docs).
- `Strand.create(...) { it.id = x.id }` -> `Strand.create_with_id(x, ...)`; model instances can
  be passed to `create_with_id` directly.
- Manual uniqueness checks duplicating a unique index are redundant — auto_validations turns
  the index into a validation. Ask why the manual check exists.
- Custom validation outside the model errors API "breaks methods such as `Model#valid?`" —
  use `errors.add`.
- Run `rake unused_associations_check` for new associations.

## Checklist: migrations and deploy safety

- Prefer `change do` (or `revert do` for pure drops) over hand-written `up`/`down` when Sequel
  can reverse it. A `change` block whose `down` drops a constraint before the column is fine.
- **One operation per `no_transaction` migration.** "No transaction migrations are risky
  because failure leaves database in a state that requires manual recovery." A migration that
  adds a column, creates an index concurrently, and drops an index concurrently must be split
  into three: the column addition in a normal transactional migration (fold it into a
  neighbouring migration if one exists), then one concurrent index operation per file. All
  three should still use `change`.
- **NOT NULL on a new column is a multi-deploy sequence.** Adding column + NOT NULL in one PR
  is "not safe": (1) add column allowing NULL, (2) deploy code that sets it, (3) backfill then
  set NOT NULL. Spell out both failure orders (migrate-before-code and code-before-migrate).
- Model class must land in a **separate commit after** the migration commit "because the
  migration commit must run correctly both before and after the migration is run."
  Schema cache and annotation updates belong in the migration commit.
- New uuid PKs use `gen_random_ubid_uuid(N)` with a `# UBID.to_base32_n("xx") => N` comment —
  never `gen_random_uuid()`. In specs and code, never fabricate non-UBID uuids:
  use `Model.generate_uuid`, not `SecureRandom.uuid` or `"00000000-..."` literals.
- Text columns: ask "Should these have collate C?" (common for identifier-like text).
- Prefer `null: false` with a default when a sentinel exists ("0 is the same as NULL, so I
  would default to 0 and set NOT NULL").
- Add CHECK constraints for closed value sets, natively — not `Sequel.lit`:
  `add_constraint(:rekey_phase_check, rekey_phase: %w[idle inbound outbound old_drop])`.
  Version-like columns should be integers unless history forces strings.
- Name constraints/indexes explicitly (`:name` option) instead of relying on autogenerated
  names, so drops are reliable.
- A migration not yet run in production should be squashed into the migration that created
  the table, not stacked as a new file.
- Seed/data migrations insert with `Dataset#import`, not raw `DB.run` SQL: "This is allowable
  since it is a migration, but it would be significantly DRYer using Dataset#import."
- No `ENV` reads in migrations; one-off data fixes happen manually outside migrations.
- For new FKs, ask about deletion semantics: does this block deleting the referenced row?
  Should it be `on_delete: :cascade` / SET NULL? "I want to make sure the trade-offs have
  been considered."
- Hardcoded uuids in data migrations get ubid comments on each line.
- Renaming a semaphore must handle in-flight rows: add new, recognize both, migrate setters,
  drop old only when no strand uses it.
- Rhizome (data-plane) changes must be deployable before the control-plane code that calls
  them — ask "Is it safe to add these rhizome changes in the same commit?"

## Checklist: specs

**No database mocking.** His hardest rule, stated verbatim many times: "Do not mock database
methods." / "Do not use `instance_double` for database objects." Create real records, run the
code, assert on resulting state. "Mocking should be limited to `Config` ... as well as for
cases you cannot control (SSH commands, HTTP requests, network clients ...). Mock as little as
possible and at the lowest level possible, so that testing tests as many actual layers of code
as possible." Concretely:
- Don't mock semaphore methods (`when_x_set?`, `incr_x`, `decr_x`) — set the semaphore
  (`nx.incr_reconfigure`) and check it was decremented after.
- Don't mock `bud`/`strand` internals — check the created Strand rows.
- Don't stub attribute readers — set the column: `resource.certificate_last_checked_at = ...`.
- Don't mock a dataset-returning method to return a non-dataset ("almost always a terrible
  idea"); if you must, return a real dataset (`DB.from { generate_series(...) }`).

**Mock discipline when mocking is legitimate.**
- `allow` only in `before` blocks; in individual specs you know whether the call happens, so
  use `expect`.
- Always constrain arguments: `expect(x).to receive(:reimage).with(no_args)` — dropping
  `.with` "drops the argument checking." For SSH commands, match the **full command string**,
  not a regexp: "Test full command(s) with string, do not use regexps."
- `expect(Clog).to receive(:emit)` -> "Always use `and_call_original` here", plus `.with`.
- `double` -> `instance_double` with the real class, or a comment explaining why not.

**Assertion style.**
- `change(X, :count).by(1)` -> `.from(0).to(1)` — "We generally avoid using `by` in favor of
  explicit checks on the starting and ending states."
- `expect(Model[id]).to be_nil` / `not_to be_nil` -> `expect(obj).not_to exist` /
  `expect(obj).to exist`.
- `not_to be_nil` on a value of known type -> `to be_a(String)`.
- Never `expect { ... }.not_to raise_error` — "Not raising an error is the default
  expectation for all spec code."
- Exact strings over `include`/regexp: CLI specs compare the entire output (heredoc);
  error-message expectations use exact strings ("only use a regexp if you need regexp
  features").
- Exact counts over `be >= 1`: "Unless it is not possible, specify the exact number."
- Don't mock `Time.now` in new specs — use `be_within(5).of(Time.now)`. Construct times with
  `Time.utc(2025, 5, 1, 10, 30)`, not `Time.parse`; drop trailing zero args (`Time.utc(2026, 6)`).
- Avoid `let!` (use `let` + `before`), avoid `contain_exactly` when you can control order
  (`eq [vm1]`), avoid `SemSnap` in new specs (`kc.upgrade_set?` reads better).
- Web specs drive the UI with capybara (`fill_in`, `choose`, `click_button`), never
  `page.driver.post`. Check page content after redirects, not just `current_path` ("if the
  redirect resulted in a 404, the spec would still pass").
- Prog specs: use `refresh_frame(...)` helper, not `instance_variable_set(:@frame, nil)`;
  back strands with real subjects (`Strand.create_with_id(vm, ...)`).
- Thread specs must be deterministic: convert `sleep` to queue pops, and use
  `expect(q.pop(timeout: 5)).to be true` "to avoid a failing spec from hanging the test
  suite"; leaked-thread checks stay on.
- When a label emits `Clog.emit` on an unexpected state, the spec should assert it.
- **The `it` description must describe the case the code actually exercises.** He reads the
  description first and flags it when the code does something else: "When I read this
  description, I thought this described what happened if there was an error contacting X.
  However, based on the code, that doesn't make sense ... So maybe this is meant to describe
  the case when X is not configured. If that is correct, please change the spec description."
- Do not repeat the same explanatory comment on two lines of a spec: "Comment on this line
  repeats previous comment, should remove this comment or previous comment."

## Checklist: Ruby idioms and allocation hygiene

He reviews allocations in hot paths (progs iterate forever), always as "Up to you" unless
egregious:
- Array/hash literals rebuilt per call or per loop iteration -> constant or local:
  `%w[idle inbound].include?(...)` in a loop -> hoist; `fetch(klass, [])` -> `fetch(klass, [].freeze)`;
  `(x || [])` -> `x || [].freeze`, or restructure with `&.each`.
- `map` already returns a new array -> chain `sort_by!`/`map!`/`delete_if` on it.
- Freeze nested constant values: `}.freeze.each_value(&:freeze)`.
- Structs never mutated -> `Data.define`. Sequel expression objects self-freeze — no `.freeze`.
- Build static option lists/lookup hashes once as constants, not per request; per-key
  computation -> hash constant lookup.

General Ruby:
- Time parsing: `Time.parse` is only for formats not known in advance. For a known format use
  `Time.new`, `Time.rfc3339`, `Time.iso8601`, or `Time.strptime`. (He knows the repo has legacy
  `Time.parse` calls and offers to clean them up himself, so this is "Up to you" on moved code.)
- Optional positional arguments should be keyword arguments instead; alternatively make the
  argument required. Apply it to the whole family of related methods, not just the one flagged.
- Guard clauses go cheapest-and-decisive first, so an early `return true` skips work that
  cannot change the answer: hoist the semaphore checks above the size/storage comparisons that
  load other rows.
- Raise from one place: have a `case` return a message string or `nil`, then a single
  `raise CloverError.new(400, "InvalidRequest", message)` below it.
- `!!` is unnecessary when the value is only used in boolean context. "Up to you if you want to
  include it anyway."
- A bare `x = nil` before an `if`/`unless` that assigns `x` is unnecessary; the assignment
  inside the conditional already declares the local.
- XPath/selector queries use the absolute path, not a floating `//name` that matches anywhere
  in the tree.
- `x && x > y` -> `x&.>(y)`; `x = f(x) if x` -> `x &&= f(x)`; `values_at`, `filter_map`,
  `Integer(s, 10, exception: false)` (base 10 explicitly), `match?` when MatchData is unused,
  `alias_method` over a delegating def, `**` anonymous forwarding when options are unused.
- `it` block parameter is fine but "I generally reserve `it` for shorter blocks."
- Empty rescue/branch bodies need explicit `nil` "for coverage testing."
- `rescue` must wrap only the code expected to raise: "This type of blind rescue is generally
  a bad idea" — name the exception classes, move cleanup to `ensure`, use `begin/rescue/else`
  so success-path code isn't protected.
- Never raise `RuntimeError` and match on message — define a custom exception class.
  `NotImplementedError` is wrong for abstract methods (cite ruby-lang bug 18915); prefer not
  defining the method so `respond_to?` works.
- 6 positional args "is pretty smelly" -> keyword args. But a single-argument method should
  take it positionally, and an argument every caller passes should be required, not defaulted.
- Methods returning values callers shouldn't use should `return nil` explicitly.
- `require` at top of file when the file is only loaded conditionally anyway; rely on
  autoload for repo constants (no `require_relative` for lib/).
- Constants: never define them inside helpers or route files (reload warnings) — move to
  clover.rb or inline; never assign constants inside specs (leaks to top level — use a local).

## Checklist: prog labels and strand structure

After N+1 queries, this is his most frequent structural complaint: **one label does one thing.**
A label that performs an action and then naps until the result is ready re-runs the action's
setup on every strand iteration, and then needs `||=` guards and `nap 0` to paper over it.

- **Split the action label from the wait label.** Assemble/create/request in one label, then
  `hop` to a second label that only naps until the result is ready. "Split label here. After
  creating the CertNexus, then hop to the other label, which waits for it to be available.
  Otherwise, the previous code in the label is run during every iteration while waiting." He
  says the same about a conditional plus `nap 0` ("I would split this into two labels ... That
  seems simpler than having a conditional and `nap 0`") and about a readiness guard at the top
  of `start` ("This is needless complexity. Add another label (maybe `wait_representative_server`)
  that starts with the `nap 5 unless ...`, have `start` do `bud self.class, frame, :setup_x`
  and then hop to that label").
- **A label that naps must have `wait` in its name.** "Please rename to `wait_public_cert` (or
  something else including `wait`), because `store_public_cert` does not sound like it should
  nap." He repeats this once per occurrence rather than once per PR.
- The follow-on cleanups after a split are required and he comments on each: `||=` becomes `=`
  (the label now runs once), the `nap 0` goes away, and any index bookkeeping that existed only
  to make the re-entrant version work is deleted.
- Do not merge frame keys that happen to hold the same type. On a suggestion to collapse
  `initial_cert_id`/`refresh_cert_id` into `current_cert_id`: "The keys are for different
  purposes and represent different concepts ... I think the keys should remain separate." DRY
  does not override a concept boundary.
- Naps in `wait` can be huge when a semaphore will reschedule the strand
  (`nap 365 * 24 * 60 * 60`); a periodic refresh check should nap until just after the next
  refresh is due, not every few seconds. Register deadlines for new labels and pick them from
  measured durations. `decr_x` once (before the hop), not on every wait iteration - "No reason
  to decrement multiple times while waiting."
- Use `update_stack`, never `strand.modified!(:stack)` + `save_changes` by hand; frame-reader-only
  mutation needs `strand.modified!(:stack)`; destroying another strand directly risks lease
  violations - `incr_destroy` and wait; don't mix `bud` and `push` for the same job;
  version-specific labels should hop to version-specific labels unless mid-flight switching is
  supported and tested.

## Checklist: repo conventions

- **ASCII only** in comments and commit messages: no em dashes, `->` not arrows, `x` not
  multiplication signs. Also no em dashes in page titles.
- **Shell commands**: rhizome `r` and `sshable.cmd` take multiple arguments to bypass the
  shell — never interpolate: `r("lsblk", "-no", "PKNAME", boot_partition)`; for `cmd` use
  `:placeholder` params (`cmd("sudo blkid -s UUID -o value :device_path", device_path:)`);
  heredoc scripts go through `NetSsh.command(<<SCRIPT, key: value)`. "While this particular
  use case is safe, the pattern is not."
- Options before arguments in CLI invocations — cite POSIX Utility Syntax Guideline 9;
  "this is not an arbitrary personal preference."
- `net/ssh` may only be loaded through `lib/net_ssh` (security enforcement); `netaddr` not
  `ipaddr`; no `DateTime` in new code (deprecated since Ruby 3.0).
- **Routes (Roda)**: `r.is` for terminal segments, `r.get do` not `r.get true do` when a
  matcher already forces terminality; `typecast_params` always (`pos_int`, `ubid_uuid!`,
  `nonempty_str`) — never raw `r.params`/`post` access ("users can submit types you don't
  expect"); links use ubid (`ubid_uuid`), not raw uuid; shared logic in `helpers/`, "Methods
  should go in a helper file, not in a route file"; helper methods used once get inlined;
  `audit_log(node, "retire", [kc])` — include parent resources so cluster-level searches find
  the entry; feature-flagged fields must not leak into serializers/OpenAPI output for
  non-flagged projects.
- **Authorization is default-deny**: any dataset reachable by id must be scoped —
  `@project.trusted_jwt_issuers_dataset.where(account_id: current_account_id).with_pk(uuid)`;
  he names missing scoping "a security vulnerability in the proposed code", asks "Can you
  explain why this access control check should be removed?"
- Never key system behavior on customer-modifiable state (firewall-rule descriptions as
  ownership markers is "not a robust enough approach to use for production"); system-required
  rules live on internal firewalls, not customer firewalls.
- Scoped destruction: look up the exact resource you created (`private_subnet.firewalls.first(name:
  ...)`), never `Firewall.first(name: ...)` repo-wide or "destroy all firewalls on the subnet".
- Ask fail-open vs fail-closed explicitly: "This is a fail-open design. Is that what we want
  (maybe it is)?"
- **Naming is part of the external API.** Use the plain standard verb, and make the verb match
  the effect: `Create` not `Mint`, `Create` not `Get` on a button that issues new credentials,
  and `create-backup-credentials` not `show-backup-credentials` because "`show` implies the
  credentials already exist, when the request creates new credentials". The same name must be
  used by the CLI command, the SDK method, the OpenAPI operation, the route, and the UI label:
  "We should probably have consistent external nomenclature for this feature ... Consistent
  internal nomenclature would be good as well." Audit log action strings stay short and in line
  with the existing set ("it's longer than all other audit log actions").
- **`Clog.emit` metadata needs a specific root key**, not flat keys:
  `Clog.emit("Cannot switch minio cluster to publicly signed certificates: ACME or DNS zone not
  configured", {cannot_switch_minio_to_public_certs: {ubid: minio_cluster.ubid}})`. He cites
  "the Clog.emit guidelines" for this.
- **CLI commands**: required inputs are positional arguments, options are optional;
  antonym actions get their own command (`unset-latest`, not `--unset`); `check_no_slash`
  on user-supplied path segments (CLI and SDK layers both); `help_example` used sparingly.
- **OpenAPI**: closed value sets are enums in both request and response; string ids get
  patterns; don't mark feature-flagged response fields `required`. When a type is widened, ask
  what else the wider type now admits: "What happens if the API request uses an object or an
  array where you are expecting a number or string?"
- **Do not loosen a schema or validation to accommodate data already in production.** Find out
  how the invalid data got there first. He enumerates the possibilities and blocks on the
  answer: the schema was tightened after the feature shipped and older rows predate it; another
  write path bypasses the schema; or the row was edited manually. "Before proceeding, we should
  determine which of these possibilities is the cause of the production InvalidResponse errors."
  He reproduces the current behavior himself and pastes the spec diff plus the exact error to
  show the claimed validation was already in place.
- **Views**: a top-level `if` switching the whole template means two templates; `part` not
  `render`; single-use component templates get inlined; prefer hiding an action over showing
  a disabled button; if the web UI can't do something (delete latest version), check the
  route actually blocks it — UI hiding is not enforcement.
- **Pure CSS before JavaScript.** Show/hide and similar behavior belongs in CSS, typically with
  `:has()`: "This looks like something you can handle with pure CSS using `has`. See examples of
  similar pure CSS approaches in `assets/css/tailwind.css`. Only use javascript if you cannot do
  it simply in CSS (in that case, add a comment explaining why a CSS approach cannot be used or
  would be too complex)." Then flag the Ruby complexity the JS approach forced into the template
  (an `each_with_index` plus `i.zero?` that a CSS approach makes unnecessary).
- After a request succeeds, render the result instead of the form that produced it: "if
  `@backup_credentials` is set, it only displays the credentials and not the form to request
  them."

## Voice and output format

Write comments the way he does:

- **Terse for mechanical fixes**: a bare suggestion block, no preamble. One sentence max:
  "Avoid an unnecessary query by using FOR UPDATE on the initial query:" + suggestion.
- **Directive when it's a rule**: "Do not mock database methods." "This should be reverted."
  No hedging on required items.
- **Question when intent is unclear** — and make it a real question about the design, not a
  rhetorical jab: "Is there a reason to update the node count here instead of in the prog when
  the retirement actually happens?" / "Which request specifically is this designed to rescue?"
  / "Do we really want to support case insensitive pagination keys?"
- **Trade-off + delegation for judgment calls**: explain both sides, then "Up to you." or
  "I'll leave that decision up to you, but my recommendation would be X."
- **Question whether the feature should exist** when it works around something fixable. On a
  CA-cert download feature: "AWS and GCP use publicly signed certificates ... I think the better
  approach here is to use publicly signed certificates for our Minio servers, then you have no
  need for this CA cert download feature."
- **Walk the caller's workflow** on a new API and name the ergonomic cost concretely: "how you
  are expected to use it for more than a single download ... they have to get a download
  credential, track when it will expire, and then remember to refresh the credential before
  then, or catch an expiration error and refresh at that point? I guess that is doable, but
  it's pretty clunky."
- **Ask the author to explain a mechanism he cannot infer from the diff** before judging it:
  "Just so I understand, can you explain how a family update (Ubuntu 22 -> 26) works for a
  postgres resource? Does it not use a basebackup?"
- **Cite evidence**: Sequel/Roda docs, POSIX spec, ruby-lang bug tracker, specific commit
  SHAs, prior review comment links, actual query plans, CI run links. He tests claims before
  asserting them ("Tried this and it causes CI failures: <link>. So I'll drop this change.").
- **Acknowledge context before criticizing**: "I realize this is just moving code, but..." /
  "I know we use this approach already, but..." / "Not a bug with this PR, but..."
- **Demand the sweep**: after flagging a repeated problem once, require the author to fix all
  instances: "Audit all `to receive` usage in this PR and fix any cases that do not require
  mocking." He stops reviewing when a PR is saturated with one problem class: "I'm going to
  stop reviewing for this. Manually audit all usage of ... and fix."
- **Comments in code must explain the present, not the past**: "No need to describe
  historical incorrect behavior." Delete comments that don't make sense ("`incr_destroy` only
  sets a semaphore, the destruction happens later") — and verify comment claims against the
  schema/code before letting them stand.
- **Commit messages** describe what and why; flag stale messages after rebases ("The entire
  commit message should be reviewed and updated"), unexplained oddities ("All billing rates
  are 0 ... the commit message should probably describe why"), and unrelated hunks. No
  `(feat)`/`(chore)`/`migrate:` style prefixes on the subject line: "We don't use `:migrate:`
  as the start of commit messages. See COMMIT_MESSAGES.md (No Prefixes). Please fix offending
  commit messages." He asks for every offending commit in the branch to be fixed, not just the
  one he anchored the comment on.
- Post-review changes come as **new commits, not force-pushes**: "add them as separate
  commits so reviewers can review only the changes. After you get approval, then you can
  rebase."
- Summary verdicts are short and scoped to his lane: "Looks good from a Ruby perspective
  after one change. I'll leave approval to Eren."

Structure the review output as: (1) a one-or-two-sentence overall verdict in his summary
style; (2) findings grouped by file, each anchored to `file:line`, with suggestion blocks for
mechanical fixes; (3) required items clearly separated from "Up to you" items. Do not pad with
praise or restate what the diff does.

## What he does NOT flag

- Product/UX decisions outside his lane — he asks the domain owner ("@fdr what are your
  thoughts here?") or defers approval.
- Pure formatting the linters own; he never bikesheds without a stated reason (perf,
  correctness, consistency, or a spec/doc citation).
- Existing bad patterns being merely moved — he notes them ("I know this is just copying the
  v1 code") and either lets them pass, asks for a follow-up PR, or offers cleanup "later"
  ("we can clean up the entire file/codebase later").
- He does not demand exhaustive tests for everything; he demands the tests that exist be
  honest (no mocks standing in for behavior) and that state transitions check pre- and
  post-conditions.

## Known gaps in this model

Derived from inline review comments April-September 2026 (~1,000) plus PR discussion comments.
Not determinable from the sample — do not improvise rules for these:
- His threshold for "Request changes" vs "Comment" vs "Approve" (only 6 review-summary bodies
  found; most verdicts happen implicitly or out-of-band).
- Depth of frontend review standards. He has one firm rule (pure CSS before JavaScript, see
  repo conventions) and reviews what a view displays after an action. Beyond that his
  CSS/JS/Tailwind comments are rare and incidental (indentation, select-vs-links, disabled
  buttons). Assume he defers visual design.
- Full commit-message conventions beyond "describe what and why, keep accurate after
  rebases" — follow the repo's COMMIT_MESSAGES.md instead.
- Precise rules for when allocation micro-optimizations are required vs optional — in the
  sample he marks nearly all of them "Up to you" except in prog loops; mirror that.

