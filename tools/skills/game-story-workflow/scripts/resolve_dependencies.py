"""Locate installed dependencies; this does not read or invoke any skill."""
import argparse
import json
from pathlib import Path


def resolve(home, names):
    roots = [home / '.agents' / 'skills', home / '.codex' / 'skills']
    return {name: next((str(root / name / 'SKILL.md') for root in roots
                        if (root / name / 'SKILL.md').is_file()), None) for name in names}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mode', choices=['narrative', 'chinese-design', 'chinese-wording'], default='narrative')
    parser.add_argument('--home', type=Path, default=Path.home(), help='Override for fixture testing only')
    args = parser.parse_args()
    names = {'narrative': ['game-narrative', 'game-design-natural-writing-zh', 'humanizer-zh'],
             'chinese-design': ['game-design-natural-writing-zh', 'humanizer-zh'],
             'chinese-wording': ['humanizer-zh']}[args.mode]
    found = resolve(args.home, names)
    print(json.dumps({'located_not_invoked': found}, ensure_ascii=False, indent=2))
    return 1 if any(path is None for path in found.values()) else 0


if __name__ == '__main__':
    raise SystemExit(main())
