import os
import sys
from string import Template
from python_graphql_client import GraphqlClient


client = GraphqlClient(endpoint='https://api.github.com/graphql')


def call_github_api(query):
    data = client.execute(
        query=query,
        # owner, name, and GH_TOKEN are global-scoped, as they are
        # assigned from within get_pr_data()
        variables={
            'owner': repo_owner,
            'name': repo_name
        },
        headers={
            'Authorization': f"Bearer {GH_TOKEN}",
            'Retry-After': '30'
        }
    )
    return data


def build_comment_subquery(cursor):
    if cursor is None:
        return ''
    return Template("""
        comments(first: 100, after: $cursor) {
            nodes {
                author { login }
            }
            pageInfo {
                hasNextPage
                endCursor
            }
        }
    """).substitute({'cursor': cursor})


def build_event_subquery(cursor):
    if cursor is None:
        return ''
    return Template("""
        timelineItems(itemTypes: LABELED_EVENT, first: 100, after: $cursor) {
            nodes {
                ... on LabeledEvent {
                    actor { login }
                    label { name }
                }
            }
            pageInfo {
                hasNextPage
                endCursor
            }
        }
    """).substitute({'cursor': cursor})


def build_page_query(pr_cursor, page_size):
    """Build query for a PR page call to GitHub API

    Query is not complete and still needs to be populated with comment and
    event queries built using build_comment_query and build_event_query

    Parameters:
        pr_cursor (str): Cursor of last requested Pull-Request
    """
    query = Template("""query PRQuery($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
            pullRequests(states: MERGED, last: $pagesize, before: $cursor) {
                nodes {
                    number
                    createdAt
                    mergedAt
                    author { login }
                    $comment_query
                    $event_query
                }
                pageInfo {
                    hasPreviousPage
                    startCursor
                }
            }
        }
        rateLimit {
            limit
            cost
            remaining
            resetAt
        }
    }
    """).safe_substitute({
        'cursor': pr_cursor,
        'pagesize': page_size
    })

    return query


def build_pr_subquery(pr_number):
    """Build single-PR subquery for a batch PR call to GitHub API

    Query is not complete and still needs to be populated with comment and
    event queries built using build_comment_query and build_event_query

    Parameters:
        pr_number (int): number/ID of requested PR
    """
    return Template("""pr$number: pullRequest(number: $number) {
        number
        createdAt
        mergedAt
        author { login }
        $comment_query
        $event_query
    }
    """).safe_substitute({'number': pr_number})


def build_pr_query(pr_subqueries):
    """Build query for batch PR call to GitHub API

    Parameters:
        pr_subqueries (List[str]): list of subqueries created by
            by calling build_pr_subquery
    """
    return Template("""query ($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
            $subqueries
        }
        rateLimit {
            limit
            cost
            remaining
            resetAt
        }
    }
    """).safe_substitute({'subqueries': ''.join(pr_subqueries)})


def format_cursor(cursor):
    """Format cursor inside double quotations as required by API"""
    return '"{}"'.format(cursor)


def get_author(author):
    """Extract author of PR or comment from GitHub API response"""
    # handle deleted GitHub accounts
    if author is None:
        return 'ghost'

    return author['login']


def find_commentors(comment_info):
    """Get list of distinct commentors from GitHub API response

    Additionally, return comment cursor if further paginating required
    """
    commentors = set([get_author(comment['author'])
                      for comment in comment_info['nodes']])

    comment_page_info = comment_info['pageInfo']
    has_comments = bool(comment_page_info['hasNextPage'])
    comment_cursor = (format_cursor(comment_page_info['endCursor'])
                      if has_comments else None)

    return commentors, comment_cursor


def find_authorizer(label_event_info):
    """Get user who set label `authorized-changes`

    Additionally, return event cursor if further paginating required
    """
    for label_event in label_event_info['nodes']:
        if label_event['label']['name'] == 'authorized-changes':
            return label_event['actor']['login'], None

    has_events = label_event_info['pageInfo']['hasNextPage']

    if not has_events:
        # for PRs from before `authorized-changes` label was used,
        # assume changes were authorized by some maintainer
        return 'maintainer', None

    return None, format_cursor(label_event_info['pageInfo']['endCursor'])


def construct_pr_dict(pr):
    """Construct dict with necessary data from API response"""
    number = pr['number']
    created_at = pr['createdAt']
    merged_at = pr['mergedAt']
    author = get_author(pr['author'])

    if 'comments' in pr:
        commentors, comment_cursor = find_commentors(pr['comments'])
    else:
        commentors = set()
        comment_cursor = None

    if 'timelineItems' in pr:
        labeler, event_cursor = find_authorizer(pr['timelineItems'])
    else:
        labeler = None
        event_cursor = None

    return number, {
        'created_at': created_at,
        'merged_at': merged_at,
        'author': author,
        'commentors': commentors,
        'labeler': labeler
    }, comment_cursor, event_cursor


def update_pr_data(pr_data, number, new_data):
    """Add comment and event data from subsequent pages of queries"""
    # perform set addition to ignore duplicate commentors
    pr_data[number]['commentors'].update(new_data['commentors'])

    if pr_data[number]['labeler'] is not None:
        return
    if new_data['labeler'] is not None:
        pr_data[number]['labeler'] = new_data['labeler']


def exhaust_comments_and_events(pr_data, remaining_prs):
    """Exhaustively query comment and event pages for list of PRs"""
    while remaining_prs:
        next_prs = []
        subqueries = []

        for number, comment_cursor, event_cursor in remaining_prs:
            subquery = Template(build_pr_subquery(number)).safe_substitute({
                'comment_query': build_comment_subquery(comment_cursor),
                'event_query': build_event_subquery(event_cursor)
            })
            subqueries.append(subquery)

        query = build_pr_query(subqueries)
        data = call_github_api(query)['data']['repository']

        for pr in data.values():
            number, pr_dict, comment_cursor, event_cursor = construct_pr_dict(pr)  # noqa
            update_pr_data(pr_data, number, pr_dict)

            if comment_cursor is not None or event_cursor is not None:
                next_prs.append((number, comment_cursor, event_cursor))

        remaining_prs = next_prs


def execute_page_query(pr_cursor, page_size):
    """Execute query for a single page of PRs

    Parameters:
        pr_cursor (int): Cursor of last requested Pull-Request
        comment_cursor (int): Cursor of last requested Comment
        event_cursor (int): Cursor of last requested event
    """
    query = Template(build_page_query(pr_cursor, page_size)).safe_substitute({
        'comment_query': build_comment_subquery("null"),
        'event_query': build_event_subquery("null")
    })

    data = call_github_api(query)['data']
    repo_data = data['repository']['pullRequests']
    rate_limit_data = data['rateLimit']

    page_info = repo_data['pageInfo']
    has_prs = bool(page_info['hasPreviousPage'])
    pr_cursor = format_cursor(page_info['startCursor']) if has_prs else None

    remaining_prs = []
    pr_data = {}
    prs = repo_data['nodes']

    for pr in prs:
        number, pr_dict, comment_cursor, event_cursor = construct_pr_dict(pr)
        pr_data[number] = pr_dict

        if comment_cursor is not None or event_cursor is not None:
            remaining_prs.append((number, comment_cursor, event_cursor))

    exhaust_comments_and_events(pr_data, remaining_prs)

    return pr_data, has_prs, pr_cursor, rate_limit_data


def get_pr_data(owner, name, last, page_size, pr_cursor,
                hide_debug_output):
    """Get PR contribution data

    Parameters:
        last (int|str): number of PRs to pull (most recent first),
            setting to "all" will query all PRs
        page_size (int): number of PRs to pull with each page query
        pr_cursor (str): cursor to last queried page
        rate_limit (bool): set True to log rate limit data with each
            page query
    """
    global repo_owner, repo_name, GH_TOKEN
    repo_owner, repo_name = owner, name

    try:
        GH_TOKEN = os.environ['GH_TOKEN']
    except KeyError:
        print('Please set your GitHub API token to the environment '
              'variable GH_TOKEN.\n'
              '\n'
              'If you have not configured an API token, you can do so '
              'by following this guide:\n'

              'https://docs.github.com/en/github/authenticating-to-github/'
              'keeping-your-account-and-data-secure/'
              'creating-a-personal-access-token\n'

              '\n'
              'You will not to request need any extra permissions; '
              'only general public access.')
        sys.exit(1)

    pr_cursor = "null" if pr_cursor is None else format_cursor(pr_cursor)

    pr_data = {}
    has_prs = True

    while has_prs and (type(last) != int or last > 0):
        if type(last) == int:
            page_size = min(page_size, last)
            last -= page_size

        data, has_prs, pr_cursor, rate_limit_data = execute_page_query(
            pr_cursor,
            page_size
        )

        pr_data.update(data)

        if not hide_debug_output:
            print(f'Rate Limit Data: {rate_limit_data}')
            print(f'PR Cursor: {pr_cursor}')
            print(f'{len(pr_data)} PRs queried\n')

    return pr_data
