#!/usr/bin/env python3
"""Claude Code status line: context window + rate limit usage."""
import json, os, sys, time

RESET = "\033[0m"
DIM = "\033[2m"
SEP = f"{DIM} | {RESET}"


def color(pct):
    if pct is None:
        return DIM
    if pct >= 90:
        return "\033[1;31m"   # bright red
    if pct >= 70:
        return "\033[33m"     # yellow
    return "\033[32m"         # green


def tokens(n):
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1000:
        return f"{n / 1000:.0f}k"
    return str(n)


def until(ts):
    if not ts:
        return ""
    secs = int(ts) - int(time.time())
    if secs <= 0:
        return ""
    h, m = divmod(secs // 60, 60)
    d, h = divmod(h, 24)
    if d:
        return f"{DIM}({d}d{h}h){RESET}"
    if h:
        return f"{DIM}({h}h{m:02d}m){RESET}"
    return f"{DIM}({m}m){RESET}"


def main():
    try:
        d = json.load(sys.stdin)
    except Exception:
        print("")
        return

    parts = []

    model = (d.get("model") or {}).get("display_name")
    if model:
        parts.append(f"\033[36m{model}{RESET}")

    cwd = (d.get("workspace") or {}).get("current_dir") or ""
    if cwd:
        home = os.path.expanduser("~")
        if cwd.startswith(home):
            cwd = "~" + cwd[len(home):]
        parts.append(f"{DIM}{cwd}{RESET}")

    ctx = d.get("context_window") or {}
    used, size = ctx.get("total_input_tokens"), ctx.get("context_window_size")
    pct = ctx.get("used_percentage")
    if size:
        pct = pct if pct is not None else 0
        parts.append(
            f"ctx {color(pct)}{pct:.0f}%{RESET}"
            f"{DIM} {tokens(used or 0)}/{tokens(size)}{RESET}"
        )

    limits = d.get("rate_limits") or {}
    for key, label in (("five_hour", "5h"), ("seven_day", "7d"), ("spend_limit", "$lim")):
        w = limits.get(key)
        if not w:
            continue
        p = w.get("used_percentage") or 0
        parts.append(f"{label} {color(p)}{p:.0f}%{RESET}{until(w.get('resets_at'))}")

    cost = (d.get("cost") or {}).get("total_cost_usd")
    if cost:
        parts.append(f"{DIM}${cost:.2f}{RESET}")

    print(SEP.join(parts))


main()
