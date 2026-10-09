# Shell-Toolkit

**A collection of Bash scripts for Debian- and Ubuntu-based systems.** Focused on system administration and automation.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-5.0%2B-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Debian](https://img.shields.io/badge/Debian-Supported-A81D33?logo=debian&logoColor=white)](https://www.debian.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-Supported-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)

## Quick Start

Clone the repository:

```bash
git clone https://github.com/rebootless/shell-toolkit.git
cd shell-toolkit
```
All shell scripts are tracked with the executable bit. If your local checkout loses executable permissions (for example, after extracting a ZIP archive or copying files to a filesystem that does not preserve Unix permissions), restore them with:

```bash
find . -type f -name "*.sh" -exec chmod +x {} \;
```

> [!TIP]
> A dry run in a disposable VM or non-production environment is always a good idea before using scripts on production systems.

## Documentation

Every script includes a metadata block immediately after the shebang describing its purpose, requirements, privileges, dependencies, and other properties (`summary`, `description`, `sudo`, `interactive`, `idempotent`, `dependencies`).
- **[`docs/index.html`](docs/index.html)**

To regenerate the documentation locally:

```bash
./generate-docs.py
```

## Requirements

- Debian- or Ubuntu-based Linux system with Bash 5.0+
- Root/`sudo` access for system-level scripts
- Some scripts require internet connection
- `python3` (standard library only) to run `generate-docs.py`
- Some scripts require additional software such as `pipx`, `flatpak`, or `npm` (see the documentation for details)

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
