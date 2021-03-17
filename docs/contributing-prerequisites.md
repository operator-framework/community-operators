# Before submitting your Operator

!!! important "First off, thanks for taking the time to contribute your Operator!"

## A primer to Kubernetes Community Operators

This project collects Operators and publishes them to OperatorHub.io, a central registry for community-powered Kubernetes Operators. For OperatorHub.io your Operator needs to work with vanilla Kubernetes.
This project also collects Community Operators that work with OpenShift to be displayed in the embedded OperatorHub. If you are new to Operators, start [here](https://github.com/operator-framework/getting-started).

## Sign Your Work

The contribution process works off standard git _Pull Requests_. Every PR needs to be signed. The sign-off is a simple line at the end of the explanation for a commit. Your signature certifies that you wrote the patch or otherwise have the right to contribute the material. The rules are pretty simple, if you can certify the below (from [developercertificate.org](https://developercertificate.org/)):

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
1 Letterman Drive
Suite D4700
San Francisco, CA, 94129

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

Then you just add a line to every git commit message:

    Signed-off-by: John Doe <john.doe@example.com>

Use your real name (sorry, no pseudonyms or anonymous contributions.)

If you set your `user.name` and `user.email` git configs, you can sign your commit automatically with `git commit -s`.

Note: If your git config information is set properly then viewing the `git log` information for your commit will look something like this:

```
Author: John Doe <john.doe@example.com>
Date:   Mon Oct 21 12:23:17 2019 -0800

    Update README

    Signed-off-by: John Doe <john.doe@example.com>
```

Notice the `Author` and `Signed-off-by` lines **must match**.


