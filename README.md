# Workflow Webhook Action

[![GitHub Release][ico-release]][link-github-release]
[![License][ico-license]](LICENSE)

A Github workflow action to call a remote webhook endpoint with a JSON or form-urlencoded
payload, and support for BASIC authentication. A hash signature is passed with each request, 
derived from the payload and a configurable secret token. The hash signature is 
identical to that which a regular Github webhook would generate, and sent in a header 
field named `X-Hub-Signature`. Therefore any existing Github webhook signature 
validation will continue to work. For more information on how to valiate the signature, 
see <https://docs.github.com/webhooks/securing/>.

By default, the values of the following GitHub workflow environment variables are sent in the 
payload: `GITHUB_REPOSITORY`, `GITHUB_REF`, `GITHUB_HEAD_REF`, `GITHUB_SHA`, `GITHUB_EVENT_NAME` 
and `GITHUB_WORKFLOW`. For more information on what is contained in these variables, see 
<https://help.github.com/en/actions/automating-your-workflow-with-github-actions/using-environment-variables>. 

These values map to the payload as follows:

```json
{
    "event": "GITHUB_EVENT_NAME",
    "repository": "GITHUB_REPOSITORY",
    "commit": "GITHUB_SHA",
    "ref": "GITHUB_REF",
    "head": "GITHUB_HEAD_REF",
    "workflow": "GITHUB_WORKFLOW"
}
```

If you are interested in receiving more comprehensive data about the GitHub event than just the 
above fields, then the action can be configured to send the whole JSON payload of the GitHub event, 
as per the `GITHUB_EVENT_PATH` variable in the environment variable documentation referenced above. 
The official documentation and reference for the payload itself can be found here: 
<https://developer.github.com/webhooks/event-payloads/>, and the details on how to configure it, 
is further down in the **Usage** section of this README.

Additional (custom) data can also be added/merged to the payload (see further down).


## Usage

The following are example snippets for a Github yaml workflow configuration. <br/>

Send the JSON (default) payload to a webhook:

```yml
    - name: Invoke deployment hook
      uses: distributhor/workflow-webhook@v1
      env:
        webhook_url: ${{ secrets.WEBHOOK_URL }}
        webhook_secret: ${{ secrets.WEBHOOK_SECRET }}
```

Will deliver a payload with the following properties:

```json
{
    "event": "push",
    "repository": "owner/project",
    "commit": "a636b6f0861bbee98039bf3df66ee13d8fbc9c74",
    "ref": "refs/heads/master",
    "head": "",
    "workflow": "Build and deploy"
}
```
<br/>

Add additional data to the payload:

```yml
    - name: Invoke deployment hook
      uses: distributhor/workflow-webhook@v1
      env:
        webhook_url: ${{ secrets.WEBHOOK_URL }}
        webhook_secret: ${{ secrets.WEBHOOK_SECRET }}
        data: '{ "weapon": "hammer", "drink" : "beer" }'
```

The additional information will become available on a `data` property,
and now look like:

```json
{
    "event": "push",
    "repository": "owner/project",
    "commit": "a636b6f0861bbee98039bf3df66ee13d8fbc9c74",
    "ref": "refs/heads/master",
    "head": "",
    "workflow": "Build and deploy",
    "data": {
        "weapon": "hammer",
        "drink": "beer"
    }
}
```

Send a form-urlencoded payload instead:

```yml
    - name: Invoke deployment hook
      uses: distributhor/workflow-webhook@v1
      env:
        webhook_type: 'form-urlencoded'
        webhook_url: ${{ secrets.WEBHOOK_URL }}
        webhook_secret: ${{ secrets.WEBHOOK_SECRET }}
        data: 'weapon=hammer&drink=beer'
```

Will set the `Content-Type` header to `application/x-www-form-urlencoded` and deliver:

```csv
"event=push&repository=owner/project&commit=a636b6f0....&weapon=hammer&drink=beer"
```

Finally, if you prefer to receive the whole original GitHub payload as JSON (as opposed 
to the default JSON snippet above), then configure the webhook with a `webhook_type` of
`json-extended`:

```yml
    - name: Invoke deployment hook
      uses: distributhor/workflow-webhook@v1
      env:
        webhook_type: 'json-extended'
        webhook_url: ${{ secrets.WEBHOOK_URL }}
        webhook_secret: ${{ secrets.WEBHOOK_SECRET }}
        data: '{ "weapon": "hammer", "drink" : "beer" }'
```

You can still add custom JSON data, which will be available on a `data` property, included 
on the GitHub payload. Importantly, the sending of the whole GitHub payload
is only supported as JSON, and not currently available as urlencoded form parameters.

## Arguments

```yml 
  webhook_url: "https://your.webhook"
```

*Required*. The HTTP URI of the webhook endpoint to invoke. The endpoint must accept 
an HTTP POST request. <br/><br/>


```yml 
  webhook_secret: "Y0uR5ecr3t"
```

*Required*. The secret with which to generate the signature hash. <br/><br/>

```yml 
  webhook_auth: "username:password"
```

Credentials to be used for BASIC authentication against the endpoint. If not configured,
authentication is assumed not to be required. If configured, it must follow the format
`username:password`, which will be used as the BASIC auth credential.<br/><br/>

```yml 
  webhook_type: "json | form-urlencoded | json-extended"
```

The default endpoint type is JSON. The argument is only required if you wish to send urlencoded form data. 
Otherwise it's optional. <br/><br/>


```yml 
  silent: true
```

To hide the output from curl set the argument `silent` to `true`. The default value is `false`.<br/><br/>


```yml 
  data: "Additional JSON or URL encoded data"
```


Additional data to include in the payload. It is optional. This data will attempted to be 
merged 'as-is' with the existing payload, and is expected to already be sanitized and valid.

In the case of JSON, the custom data will be available on a property named `data`, and it will be 
run through a JSON validator. Invalid JSON will cause the action to break and exit. For example, using 
single quotes for JSON properties and values instead of double quotes, will show the 
following (somewhat confusing) message in your workflow output: `Invalid numeric literal`. 
Such messages are the direct output from the validation library <https://stedolan.github.io/jq/>. 
The supplied JSON must pass the validation run through `jq`.


## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.

[ico-release]: https://img.shields.io/github/tag/distributhor/workflow-webhook.svg
[ico-license]: https://img.shields.io/badge/license-MIT-brightgreen.svg
[link-github-release]: https://github.com/distributhor/workflow-webhook/releases