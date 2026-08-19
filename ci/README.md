# ci/

The workflows every published template gets.

`.github/workflows/` next to this directory is the monorepo's own CI: it builds
every template together and checks the things only the monorepo can check.
These files are different. They belong to a single project - the one somebody
starts after pressing **Use this template** - and they are copied into
`.github/workflows/` by `scripts/publish-template.sh`.

A template that needs something else puts its own file in
`templates/<name>/.github/workflows/`. A file with the same name wins over the
one here, so a template can replace a shared workflow without editing it for
everyone.
