# Operator Flow

Script to measure contribution performance on https://github.com/operator-framework/community-operators

To use this, you need a GitHub token, which you can create by following this [guide](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token). You will not need any extra permissions; just general public access.

running with -h flag will show you usage data:
```
$ python3 measure-operator-flow.py -h
usage: measure-operator-flow.py [-h] [-l N] [-p K] [-c C] [-r R] [-a ADMIN [ADMIN ...]] [-o OUTPUT_FILE] [--hide-debug-output]

measure pull request performance on https://github.com/operator-framework/community-operators (you will require a GitHub API token set to the environment variable GH_TOKEN)

optional arguments:
  -h, --help            show this help message and exit
  -l N, --last N        request only last N pull requests (accept int or "all")
  -p K, --page-size K   request K pull requests per GraphQL page
  -c C, --pr-cursor C   startCursor for GraphQL page
  -r R, --repo R        git repository to be queried
  -a ADMIN [ADMIN ...], --admins ADMIN [ADMIN ...]
                        list of maintainers for given repo
  -o OUTPUT_FILE, --output-file OUTPUT_FILE
                        write JSON-formatted PR data to provided file
  --hide-debug-output   only log JSON-formatted PR data
```
