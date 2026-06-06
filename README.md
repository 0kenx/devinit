# devinit

Standalone project-template initializer.

`devinit` copies one of the bundled templates from `./templates` into a target
directory, copies the shared `_lib`, initializes git, stages the generated files,
and runs `direnv allow` when an `.envrc` is present.

## Usage

```sh
./devinit rust
./devinit python --target ~/projects/my-python-app
./devinit --list
```

Supported languages:

- `rust` / `rs`
- `python` / `py`
- `solidity` / `sol`
- `typescript` / `ts`
- `elixir` / `ex`
- `zig`
- `go` / `golang`

## Layout

- `devinit`: Bash entrypoint.
- `templates/optimized-pre-config-*`: Language templates.
- `templates/_lib`: Shared NixOS VM module and shared tools used by templates.

By default the script loads templates relative to itself. You can override that
with `--templates-dir DIR` or `DEVINIT_TEMPLATES_DIR=DIR`.
