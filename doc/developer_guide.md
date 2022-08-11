# Developer Guide

Just use your Dart knowledge and best practices, and communicate through Github Issues before making large changes.

Since there are two packages, we use `melos` to make things easier.

Install it: 

`dart pub global activate melos`

Add overrides so that your `creator` package depends on your local `creator_core` package:

`melos bootstrap`

Make code changes, then test both packages (see melos.yaml for what it does):

`melos test`

Commit and create PR.
