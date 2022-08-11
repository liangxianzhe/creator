# Developer Guide

Just use your Dart knowledge and best practices, and communicate through Github Issues before making large changes.

## Setup

Since there are two packages, we use `melos` to make things easier.

Install it: 

`dart pub global activate melos`

Add overrides so that your `creator` package depends on your local `creator_core` package:

`melos bootstrap`

Make code changes, then test both packages (see melos.yaml for what it does):

`melos test`

Commit and create PR.

## Publishing a new version to pub.dev:

This is for the package owner.

Update version in `pubspec.yaml` in both packages. Update `CHANGELOG.md` in both packages.

`melos clean` to clear the local dependency overrides.

`melos publish` to dry run the publish.

`melos publish --no-dry-run` to publish the change.

Commit and push the change to github.