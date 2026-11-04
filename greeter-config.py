#!/usr/bin/env python3
"""Set keys in noctalia-greeter's greeter.toml without clobbering the rest.

Usage: greeter-config.py FILE 'table|key|toml-value' ...
  e.g. greeter-config.py /var/lib/noctalia-greeter/greeter.toml \
         'clock|position|"top-center"' 'appearance|hide_logo|true'

Line-based on purpose (no TOML writer in the stdlib): for each setting it
replaces `key = ...` inside `[table]`, or inserts it at the end of that
table, or appends the table. Comments and unrelated keys are preserved.
Prints what changed. Validates the result with tomllib before writing.
Used by setup-greeter.sh (run via sudo, since the file is root/greeter-owned).
"""
import pathlib
import re
import sys
import tomllib


def upsert(lines, table, key, value):
    header = f"[{table}]"
    start = next((i for i, l in enumerate(lines) if l.strip() == header), None)
    if start is None:
        if lines and lines[-1].strip():
            lines.append("")
        lines += [header, f"{key} = {value}"]
        return "added"
    end = next((i for i in range(start + 1, len(lines))
                if re.match(r"\s*\[", lines[i])), len(lines))
    key_re = re.compile(rf"\s*{re.escape(key)}\s*=")
    for i in range(start + 1, end):
        if key_re.match(lines[i]):
            new = f"{key} = {value}"
            if lines[i].strip() == new:
                return "unchanged"
            lines[i] = new
            return "updated"
    # insert after the table's last non-blank line
    pos = end
    while pos - 1 > start and not lines[pos - 1].strip():
        pos -= 1
    lines.insert(pos, f"{key} = {value}")
    return "added"


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    path = pathlib.Path(sys.argv[1])
    lines = path.read_text().splitlines() if path.exists() else []
    for spec in sys.argv[2:]:
        table, key, value = spec.split("|", 2)
        print(f"   {upsert(lines, table, key, value):9} [{table}] {key} = {value}")
    text = "\n".join(lines) + "\n"
    tomllib.loads(text)  # refuse to write a file the greeter can't parse
    path.write_text(text)


if __name__ == "__main__":
    main()
