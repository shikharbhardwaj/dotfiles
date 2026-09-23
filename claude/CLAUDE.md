# Global instructions

## Communication style

Always write to the user in ASD-STE100 Simplified Technical English.

- Write short sentences. Keep procedure sentences to 20 words or fewer. Keep descriptive sentences to 25 words or fewer.
- Write one instruction in one sentence.
- Use the active voice.
- Use the simple present, past, or future tense. Do not use complex tenses.
- Use approved, single-meaning words. Use one word for one meaning and one meaning for one word.
- Use the articles "a" and "the". Do not omit them.
- Do not use slang, idioms, or long noun clusters (3 words or fewer).
- Start a warning or a caution with the command.
- Keep the technical accuracy. This applies to prose only. Keep code, commands, and file paths exact.

---

## General coding style guidelines

### Git and commit workflow

**Never commit on `main`.** Do the work on a feature branch. If HEAD is on `main`, create a branch first, then commit there. The user keeps `main` in sync with `origin/main` and merges through feature branches only. A local commit on `main` breaks that flow. When a fix already exists upstream on `main`, do not re-add it on the feature branch. A rebase drops the duplicate.

**Commit granularity (Jeremy Evans style).**
- Put each database migration in its own separate commit, together with the regenerated `cache/schema.cache`. Do not bundle a migration with the code that uses the new columns.
- Break the rest of a feature into small, individually-reviewable commits. Make each commit green (tests and rubocop pass at that commit). Order the commits so a reviewer can read them one at a time (model support → plumbing → producer prog → consumer prog). Give an independent bug fix its own commit.
- Look at how a comparable past feature was landed to model the slicing.
- Verify each commit independently: `git rebase main --exec "mise exec -- bundle exec rspec <relevant specs>"`.

**Rebase diff stability.** When you rebase, reorder, or squash a branch, preserve the commit content. Do NOT re-author commits by hand (reset + cherry-pick + fresh re-commit). A hand-rebuilt branch looks clean but silently drifts content: it can drop a whole commit or revert a real logic guard while tests still pass.
- Use content-preserving operations only: `git rebase --onto <newbase> <oldbase> <branch>`, `--fixup`/`--autosquash`, or `git cherry-pick` of the actual original commits.
- After a rebase, diff the pre-rebase cumulative feature diff against the post-rebase one to confirm nothing was lost: `git diff $(git merge-base OLD origin/main) OLD` vs `git diff origin/main HEAD`.
- Never `git commit` a re-typed version of an existing commit's content.

**Commit messages.** Use the commit message to document the rationale behind a
change, what else was considered and any references to external source material
relevant to the change.

Here is an example of a commit message for adding this document, with annotations:

Document the commit message rules for Clover                       | Subject: ~50 chars, imperative mood

The motivation and guidelines for commit messages have never been  | Body: Hard-wrapped at 72 chars
written for this project before, leading to confusion. We now have |
enough contributors that a formal treatment is necessary.          |


### Code structure

**DRY.** Don't repeat the same construct multiple times, especially when the
same logic repeats across file/module boundaries.

**Comments.** Comments should be used sparingly, to explain something not
obvious from reading the code. The commit message is always preferred for
describing the rationale behind a change. If an implementation detail differs
from the obvious way, it is acceptable to add a comment. Keep comments terse,
visual clutter in the code is not acceptable.  Avoid comments like `# Wait
until X` or `# Start all the servers now` when the code already reads that way.


# Ubicloud repo

The rules below apply to the `ubicloud/ubicloud` repository. Do not apply them to other repositories.

## Ruby toolchain

Use `mise` to run Ruby and bundle commands, not rbenv or the system Ruby. The system Ruby (2.6) is too old and lacks the right bundler version.

Prefix Ruby CLI commands like this: `source ~/.zshrc 2>/dev/null; mise exec -- bundle exec <command>` (for example `bundle exec rspec`, `bundle exec rake`).

## Specs

Only mock `Config`, `sshable` (`_cmd`), and network-interacting clients. Do NOT mock the prog under test (`nx`), models (`vm`, `minio_server`, `dns_zone`, ...), or framework methods. Drive them with real state and assert on the resulting state.

- `register_deadline` → let it run; assert `nx.strand.stack[0]["deadline_target"]`.
- `bud`/`push` → let it run; assert the child strand (`nx.strand.children.first.prog`, its `stack[0]`).
- `vm.ip4_string`/`ip4` → give the VM a real address: `AssignedVmAddress.create(dst_vm_id: vm.id, ip: "1.1.1.1/32")`.
- `dns_zone.insert_record` → let it run (DB-only); assert the `DnsRecord` row.
- `Clog.emit` → do not assert the log; assert the resulting state.

This pairs with the no-DB-mocking convention: use real records, real semaphores, and assert on `Semaphore.where(...).count` or column state.

## Sequel

To prefer one value over another in a single query, use `.order(column: preferred_value).last`. Sequel translates `order(column: value)` into `ORDER BY (column = value)`, a boolean. `.last` then returns the row where the condition is true, and falls back to another match if none exists. This avoids two separate queries.

## Sshable in ad-hoc scripts

When an ad-hoc pry or ops script runs `sshable.cmd` across many servers, wrap each call in a rescue with a short retry loop (about 3 attempts, with a brief sleep between). Live SSH connections drop intermittently, and a single transient error must not abort a fleet-wide sweep. Record the final error in the output row instead of raising, so one unreachable server does not lose the data from the other servers.

## Deploying rhizome changes

To deploy rhizome script changes to a running server, run `InstallRhizome` first, THEN trigger the reconfigure semaphore. Rhizome scripts are uploaded during bootstrapping and do not auto-update. The reconfigure semaphore alone (for example `configure_logs`) re-runs the already-deployed script, not the new code.

```ruby
pg = udec "pg....."
sts = pg.servers.map do |ps|
  Strand.create_with_id(
    prog: "InstallRhizome", label: "start", stack:
    [{subject_id: ps.vm.id, target_folder: "postgres", install_specs: false}])
end
# After InstallRhizome completes, also trigger the reconfigure semaphore:
pg.servers.each { |ps| ps.incr_configure_logs }
```

A `rhizome/host/lib/vm_setup.rb` change also needs `InstallRhizome` to reach the hosts.


