def branch_name: (.branch // "detached") | sub(":refs/pull/[0-9]+/head$"; "");
def path_pr: try (.worktree.path | capture("/pr-(?<number>[0-9]+)$").number) catch null;
.items as $items |
(
  $items[] | select(.worktree) |
  . as $item |
  (branch_name) as $branch |
  (path_pr // ($prs | sort_by(.updatedAt) | reverse | map(select(.headRefName == $branch)) | .[0].number | if . == null then null else tostring end)) as $number |
  ["wt", .worktree.path, ($number // "-"),
    (if $number then "#\($number) \($branch)" else $branch end),
    (.display.symbols // ""), (.head.subject // "")] | @tsv
),
(
  $prs | sort_by(.updatedAt) | reverse | .[] |
  select(.state == "OPEN") |
  . as $pr |
  select(any($items[]; .worktree and (branch_name == $pr.headRefName)) | not) |
  ["pr", (.number | tostring), (.number | tostring),
    "#\(.number) \(.headRefName)", "open PR", .title] | @tsv
)
