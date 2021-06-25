#!/usr/bin/env python

import sys
import argparse
from datetime import datetime
import json
import pprint

from requests.api import options
from graphql_handler import get_pr_data


def compute_duration(created_at, merged_at):
    """Compute duration that a merged PR was open (in seconds)"""
    format_str = r"%Y-%m-%dT%H:%M:%SZ"
    date_created = datetime.strptime(created_at, format_str)
    date_merged = datetime.strptime(merged_at, format_str)
    time_diff = (date_merged - date_created).total_seconds()
    return int(time_diff)


def process_pr_data(pr_data, maintainers):
    processed_pr_data = []

    for number, pr in pr_data.items():
        time_to_merge = compute_duration(pr['created_at'], pr['merged_at'])

        if pr['labeler'] in maintainers:
            authorizer = 'maintainer'
        else:
            authorizer = 'bot'

        if maintainers & pr['commentors']:
            interaction = 'comment by maintainer'
        elif authorizer == 'maintainer':
            interaction = 'maintainer set authorized-changes'
        else:
            interaction = 'none'

        processed_pr_data.append({
            'number': number,
            'author': pr['author'],
            'date_created': pr['created_at'],
            'time_to_merge': time_to_merge,
            'authorizer': authorizer,
            'interaction': interaction
        })
    
    return processed_pr_data


def parse_last(last):
    """Parse argument provided with --last command line option
    
    Accepts either int (to specify how many PRs to pull) or "all"
    (to pull all)
    """
    try:
        return int(last)
    except ValueError:
        if last != 'all':
            print(f'invalid argument for option --last: {last}')
            sys.exit(1)
        return last



def parse_repo(repo):
    """Parse full name or url of repo to give us owner and name"""
    # this lets us ignore `https://github.com/`, etc.
    return repo.split('/')[-2:]


def parse_args(argv):
    """Parse command line args"""
    description = ('measure pull request performance on '
    'https://github.com/operator-framework/community-operators '
    '(you will require a GitHub API token set to the environment variable '
    'GH_TOKEN)\n')

    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('-l', '--last', metavar='N', type=parse_last,
                        default=100,
                        help='request only last N pull requests '
                             '(accept int or "all")')

    parser.add_argument('-p', '--page-size', metavar='K', type=int, 
                        default=100,
                        help='request K pull requests per GraphQL page')

    parser.add_argument('-c', '--pr-cursor', metavar='C', type=str,
                        help='startCursor for GraphQL page')

    parser.add_argument('-r', '--repo', metavar='R', type=parse_repo,
                        help='git repository to be queried')

    parser.add_argument('-a', '--admins', metavar='ADMIN',
                        type=str, nargs='+',
                        help='list of maintainers for given repo')
    
    parser.add_argument('-o', '--output-file', type=str,
                        help='write JSON-formatted PR data to provided file')

    parser.add_argument('--hide-debug-output', action='store_true',
                        default=False,
                        help='only log JSON-formatted PR data (this can be '
                        'helpful when writing console output to JSON file)')
    
    args = parser.parse_args()

    if (args.repo is not None) and (args.admins is None):
        parser.error('must provide admins for specified repository')

    if args.repo is None:
        args.repo = 'operator-framework', 'community-operators'
    
    if args.admins is None:
        args.admins = 'mvalarh', 'J0zi'
    
    return args


def main(argv):
    args = parse_args(argv)
    
    last = args.last
    page_size = args.page_size
    pr_cursor = args.pr_cursor

    repo_owner, repo_name = args.repo

    admins = args.admins
    maintainers = set(['maintainer', *admins])

    output_file = args.output_file
    hide_debug_output = args.hide_debug_output

    if not hide_debug_output:
        print(f'Running PR querying {last} PRs with page size {page_size} '
              f'from repo https://github.com/{repo_owner}/{repo_name} with '
              f'maintainers {admins}')

        print(f'Starting from', (f'PR cursor {pr_cursor}'
                                 if pr_cursor is not None else 'latest PR'))

        if last > 100:
            print('this may take a while...\n')

    pr_data = get_pr_data(repo_owner, repo_name, last, page_size, pr_cursor,
                          hide_debug_output)

    processed_pr_data = process_pr_data(pr_data, maintainers)

    if output_file is not None:
        with open(output_file, 'w') as f:
            json.dump(processed_pr_data, f, indent=4)
        print(f'wrote results to {output_file}')

    else:
        pp = pprint.PrettyPrinter()
        pp.pprint(processed_pr_data)


if __name__ == '__main__':
    main(sys.argv[1:])
