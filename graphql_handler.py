import os
import pprint
from string import Template
from python_graphql_client import GraphqlClient


client = GraphqlClient(endpoint='https://api.github.com/graphql')


def call_github_api(query):
    data = client.execute(
        query=query,
        variables={
            "owner": "operator-framework",
            "name": "community-operators"
        },
        headers={'Authorization': f"Bearer {os.environ['GH_TOKEN']}"}
    )
    return data


def build_comment_query(cursor):
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


def build_event_query(cursor):
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
    """Build query for a multi-PR call to GitHub API

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


def build_pr_query(pr_number):
    """Build query for a single-PR call to GitHub API

    Query is not complete and still needs to be populated with comment and
    event queries built using build_comment_query and build_event_query

    Parameters:
        pr_number (int): Number of PRs to request (reverse-chronological
        order)
    """
    query = Template("""query PRQuery($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
            pullRequest(number: $number) {
                createdAt
                mergedAt
                author { login }
                $comment_query
                $event_query
            }
        }
        rateLimit {
            limit
            cost
            remaining
            resetAt
        }
    }
    """).safe_substitute({'number': pr_number})

    return query


def find_authorizer(label_event_info):
    for label_event in label_event_info['nodes']:
        if label_event['label']['name'] == 'authorized-changes':
            return label_event['actor']['login'], False, None

    has_events = label_event_info['pageInfo']['hasNextPage']
    if not has_events:
        return 'maintainer', False, None
    else:
        return None, True, label_event_info['pageInfo']['endCursor']


def execute_page_query(pr_cursor, page_size):
    """Execute query for a single page of PRs

    Parameters:
        pr_cursor (int): Cursor of last requested Pull-Request
        comment_cursor (int): Cursor of last requested Comment
        event_cursor (int): Cursor of last requested event
    """
    query = Template(build_page_query(pr_cursor, page_size)).safe_substitute({
        'comment_query': build_comment_query("null"),
        'event_query': build_event_query("null")
    })

    data = call_github_api(query)['data']['repository']['pullRequests']

    page_info = data['pageInfo']
    has_prs = bool(page_info['hasPreviousPage'])
    pr_cursor = '"{}"'.format(page_info['startCursor']) if has_prs else None

    pr_data = {}
    prs = data['nodes']

    for pr in prs:
        number = pr['number']
        created_at = pr['createdAt']
        merged_at = pr['mergedAt']
        author = pr['author']

        comments = pr['comments']['nodes']
        commentors = set([comment['author']['login'] for comment in comments])

        comment_page_info = pr['comments']['pageInfo']
        has_comments = bool(comment_page_info['hasNextPage'])
        comment_cursor = (comment_page_info['endCursor']
                          if has_comments else None)

        label_event_info = pr['timelineItems']
        labeler, has_events, event_cursor = find_authorizer(label_event_info)

        if has_comments or has_events:
            print(comment_cursor, event_cursor)  # so flake8 doesn't complain

        pr_data[number] = {
            'created_at': created_at,
            'merged_at': merged_at,
            'author': author,
            'commentors': commentors,
            'labeler': labeler
        }

    return pr_data, has_prs, pr_cursor


def exhaust_comments_and_events():
    """Exhaustively query comment and event pages for list of PRs"""
    pass


def get_pr_data(last=None, page_size=100):
    """Get PR contribution data

    Parameters:
        last (int): number of PRs to pull (most recent first)
    """
    pr_cursor = "null"

    pr_data = {}
    has_prs = True
    i = 0

    while has_prs and (last is None or last > 0):
        print(f'\niteration {i + 1}')
        if last is not None:
            page_size = min(page_size, last)
            last -= page_size

        data, has_prs, pr_cursor = execute_page_query(pr_cursor, page_size)
        pp = pprint.PrettyPrinter()
        pp.pprint(data)

        i += 1

        pr_data.update(data)

    return pr_data
