_default:
    @just --list

test:
    sbcl --script scripts/test.lisp

validate:
    scripts/smoke.sh

review: validate

browser-smoke:
    scripts/check-reviewer-demos.sh

review-diff:
    git diff --stat && git diff --check
