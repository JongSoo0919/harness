# Stage Routing

| Situation | Stage |
| --- | --- |
| Goal, scope, users, or constraints are unclear | `plan` |
| Approved plan needs implementation | `dev` |
| Change needs verification | `test` |
| Deployment, observability, config, scheduler, external dependency, or rollback risk exists | `ops` |
| Docs, wiki, API, workflow, or decision records need updates | `document` |
| Commit, push, PR, or team summary is needed | `share` |

Full workflow:

```text
request -> plan -> approval -> dev -> test -> ops -> document -> share -> approval -> PR
```

Single-stage work is allowed. If prior outputs are missing, use the user request, current repository, git diff, and relevant docs. Record that prior outputs were missing.
