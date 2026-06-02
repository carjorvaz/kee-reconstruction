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
    jj diff --tool difft

jj-status:
    jj status

jj-diff:
    jj diff

jj-ops:
    jj op log
