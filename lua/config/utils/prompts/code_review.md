---
name: Code Review
interaction: chat
description: Review code changes
---

## user

Please review this code:

```${context.filetype}
${utils.code}
```

Here's the git diff:

```diff
${utils.git_diff}
```
