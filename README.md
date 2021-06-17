# Operator Flow

Script to measure contribution performance on https://github.com/operator-framework/community-operators

To use this, you need a GitHub token, which you can create by following this [guide](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token). You will not need any extra permissions; just general public access.

running with -h flag will show you usage data:
```
$ python3 measure-operator-flow.py -h
usage: ./measure-operator-flow.py [options]

measure pull request performance on https://github.com/operator-framework/community-operators

you will require a GitHub API token set to the environment variable GH_TOKEN

options:
    [-l, --last] <n>       requests only last n pull requests
    [-p, --page-size] <k>  requests k pull requests per GraphQL page
    [-c, pr-cursor] <c>    startCursor for GraphQL page
    --show-pr-cursor       log startCursor of each GraphQL page requested
    --show-rate-limit      log rate limit data during each page request
```
