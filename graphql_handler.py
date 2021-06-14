import os
import json
from string import Template
from python_graphql_client import GraphqlClient


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


def build_page_query(pr_cursor, comment_cursor, event_cursor):
    """Build query for a multi-PR call to GitHub API

    Parameters:
        pr_cursor (int): Cursor of last requested Pull-Request
        comment_cursor (int): Cursor of last requested Comment
        event_cursor (int): Cursor of last requested event
    """
    comment_query = build_comment_query(comment_cursor)
    event_query = build_event_query(event_cursor)

    query = Template("""query PRQuery($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
            pullRequests(states: MERGED, last: 100, before: $cursor) {
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
    """).safe_substitute({'cursor': pr_cursor,
                          'comment_query': comment_query,
                          'event_query': event_query})

    return query


def build_pr_query(pr_number, comment_cursor, event_cursor):
    """Build query for a single-PR call to GitHub API

    Parameters:
        pr_number (int): Number of PR to request
        comment_cursor (int): Cursor of last requested Comment
        event_cursor (int): Cursor of last requested event
    """
    comment_query = build_comment_query(comment_cursor)
    event_query = build_event_query(event_cursor)

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
    """).safe_substitute({'number': pr_number,
                          'comment_query': comment_query,
                          'event_query': event_query})

    return query


def execute_page_query(pr_cursor, comment_cursor, timeline_cursor):
    """Execute query for a single page of PRs

    Parameters:
        pr_cursor (int): Cursor of last requested Pull-Request
        comment_cursor (int): Cursor of last requested Comment
        event_cursor (int): Cursor of last requested event
    """
    return client.execute(
        query=build_page_query(pr_cursor, comment_cursor, timeline_cursor),
        variables={
            "owner": "operator-framework",
            "name": "community-operators"
        },
        headers={'Authorization': f"Bearer {os.environ['GH_TOKEN']}"}
    )


def exhaust_comments_and_events():
    """Exhaustively query comment and event pages for list of PRs"""
    pass


def get_pr_data(last=None):
    """Get PR contribution data

    Parameters:
        last (int): number of PRs to pull (most recent first)
    """ 
    global client
    client = GraphqlClient(endpoint='https://api.github.com/graphql')

    remaining = last
    pr_cursor = "null"
    comment_cursor = "null"
    timeline_cursor = "null"

    pr_data = []
    has_prs = True

    while has_prs and (remaining is None or remaining >= 0):
        data = execute_page_query(pr_cursor, comment_cursor, timeline_cursor)
        print(data)

        page_info = data['data']['repository']['pullRequests']['pageInfo']
        has_prs = bool(page_info['hasPreviousPage'])
        pr_cursor = page_info['startCursor']
        if remaining is not None: remaining -= 100

        pr_data = data

    return pr_data
