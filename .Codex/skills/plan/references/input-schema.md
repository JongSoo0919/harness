# Input Schema

Use this shape for `docs/work/YYYY-MM-DD-task/input.yaml`.

```yaml
task:
  name:
  type: product|feature|bugfix|maintenance|architecture|operation|documentation
  summary:
context:
  current_state:
  target_users:
  problem:
  desired_outcome:
scope:
  in:
  out:
constraints:
  technical:
  business:
  time:
risks:
  items:
approval:
  planApproved: false
verification:
  required:
documentation:
  required:
git:
  branch:
```
