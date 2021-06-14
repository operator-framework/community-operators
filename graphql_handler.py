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


def build_query(pr_cursor, comment_cursor, event_cursor):
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


def get_pr_data():
    client = GraphqlClient(endpoint='https://api.github.com/graphql')

    pr_cursor = "null"
    comment_cursor = "null"
    timeline_cursor = "null"

    data = client.execute(
        query=build_query(pr_cursor, comment_cursor, timeline_cursor),
        variables={"owner": "operator-framework", "name": "community-operators"},
        headers={'Authorization': f"Bearer {os.environ['GH_TOKEN']}"}
    )

    return json.dumps(data, indent=2)
