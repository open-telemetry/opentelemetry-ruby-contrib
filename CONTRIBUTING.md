# Contributing

We welcome your contributions to this project!

Please read the [OpenTelemetry Contributor Guide][otel-contributor-guide]
for general information on how to contribute including signing the Contributor License Agreement, the Code of Conduct, and Community Expectations.

## Before you begin

### Specifications / Guidelines

As with other OpenTelemetry clients, opentelemetry-ruby follows the
[opentelemetry-specification][otel-specification] and the
[library guidelines][otel-lib-guidelines].

### Focus on Capabilities, Not Structure Compliance

OpenTelemetry is an evolving specification, one where the desires and
use cases are clear, but the method to satisfy those use cases are not.

As such, Contributions should provide functionality and behavior that
conforms to the specification, but the interface and structure are flexible.

It is preferable to have contributions follow the idioms of the language
rather than conform to specific API names or argument patterns in the spec.

For a deeper discussion, see: https://github.com/open-telemetry/opentelemetry-specification/issues/165

## Getting started

Everyone is welcome to contribute code via GitHub Pull Requests (PRs).

### Fork the repo

Fork the project on GitHub by clicking the `Fork` button at the top of the
repository and clone your fork locally:

```sh
git clone git@github.com:YOUR_GITHUB_NAME/opentelemetry-ruby-contrib.git
```

or
```sh
git clone https://github.com/YOUR_GITHUB_NAME/opentelemetry-ruby-contrib.git
```

It can be helpful to add the `open-telemetry/opentelemetry-ruby-contrib` repo as a
remote so you can track changes (we're adding as `upstream` here):

```sh
git remote add upstream git@github.com:open-telemetry/opentelemetry-ruby-contrib.git
```

or

```sh
git remote add upstream https://github.com/open-telemetry/opentelemetry-ruby-contrib.git
```

For more detailed information on this workflow read the
[GitHub Workflow][otel-github-workflow].

### Run the tests

_Setting up a running Ruby environment is outside the scope of this document._

This repository contains multiple Ruby gems:

 *  Various instrumentation gems located in subdirectories of `instrumentation`
 *  Various resource detector gems located in subdirectories of `resources`
 *  `opentelemetry-propagator-xray` located in the `propagator/xray` directory
 *  `opentelemetry-propagator-ottrace` located in the `propagator/ottrace` directory

Each of these gems has its configuration and tests.

For example, to test `opentelemetry-instrumentation-action_pack` you would:

 1. Change directory to `instrumentation/action_pack`
 2. Install the bundle with `bundle install`
 3. Run the tests with `bundle exec rake`

### Docker setup

We use Docker Compose to configure and build services used in development and
testing. This makes it easier to test against libraries that have dependencies,
such as the MySQL instrumentation gem. See `docker-compose.yml` for specific
configuration details.

The services provided include:

 *  `app` - main container environment scoped to the `/app` directory. Used
    primarily to build and tag the `opentelemetry/opentelemetry-ruby-contrib:latest` image.
 *  `x-instrumentation-<library_name>` - container environment scoped to a specific instrumentation library. See `docker-compose.yml` for available services.

To test using Docker:

 1. Install Docker and Docker Compose for your operating system
 2. Get the latest code for the project
 3. Build the `opentelemetry/opentelemetry-ruby-contrib` image
    * `docker-compose build`
    * This makes the image available locally
 4. Install dependencies for the service you want to interact with
    *  `docker-compose run <service-name> bundle install`
 5. Run the tests
    *  `docker-compose run <service-name> bundle exec rake test`

## Processing and visualizing traces locally

You may wish to test your changes against an [OpenTelemetry collector](https://github.com/open-telemetry/opentelemetry-collector). To facilitate this, we provide configuration in `docker-compose.yml` that should be sufficient.

By default, docker-compose launches all services, including the collector - `docker-compose up` from the repository root is sufficient.
However, if you only wish to launch the collector, run `docker-compose up jaeger otelcol` instead.

The collector listens on the default HTTP and GRPC ports (`4318` and `4317`, respectively). You can visualize the traces from your work via the Jaeger trace UI by visiting `localhost:16686` in your browser.

## Make your modifications

Some important tips to keep in mind when making your modifications.

### Always work in a branch from your fork

```sh
git checkout -b my-feature-branch
```

Do not open a pull request from your own main branch, because we squash when
merging, and that will cause you problems when you update your fork after
merging.

### Use conventional commit messages

All commits to the main repository should follow the
[conventional commit](https://conventionalcommits.org) standard. In a nutshell,
this means commit messages should begin with a semantic tag such as `feat:`,
`fix:`, `docs:`, `test:`, `refactor:`, etc... Our release tooling uses these tags
to determine the semantics of your commit, such as how it affects semantic
versioning of the libraries, and to generate changelogs from commit
descriptions. If you are not familiar with conventional commits, please review
the [specification](https://conventionalcommits.org). It is pretty simple.

If you open a pull request without a conventional commit message, your reviewer
may ask you to amend the commit message.

### Documentation and style

We use rubocop to check style rules for this repository. Please run rubocop:

```sh
bundle install
bundle exec rake rubocop
```

to ensure that your code complies before opening a pull request.

We also use Yard to generate class documentation automatically. Among other
things, this means:

 *  Methods and arguments should include the appropriate type annotations
 *  You can use markdown formatting in your documentation comments

You can generate the docs locally to see the results, by running:

```sh
bundle install
bundle exec rake yard
```

## Create a Pull Request

You'll need to create a Pull Request once you've finished your work.
The [Kubernetes GitHub Workflow][kube-github-workflow-pr] document has
a significant section on PRs.

Open the PR against the `open-telemetry/opentelemetry-ruby-contrib` repository.

Please put `[WIP]` in the title, or create it as a [`Draft`][github-draft] PR
if the PR is not ready for review.

### Create one pull request per change

An important implication of [conventional commits](https://conventionalcommits.org)
is that each commit message can describe at most one change. For example, if you
add a feature and fix a bug, the commit message cannot include both the `feat:`
and `fix:` semantic tags, so you should split your change into multiple commits.

The same goes for pull requests. When we merge pull requests, we generally do
so by squashing, so your pull request will result in a single commit in the
repository, and in turn will correspond to exactly one entry in the changelog.
Therefore, please scope each pull request to include a single change.

### Sign the Contributor License Agreement (CLA)

All PRs are automatically checked for a signed CLA. Your first PR fails this
check if you haven't signed the [CNCF CLA][cncf-cla].

The failed check displays a link to `details` which walks you through the
process. Don't worry it's painless!

### Review and feedback

PRs require a review from one or more of the [code owners](CODEOWNERS) before
merge. You'll probably get some feedback from these fine folks which helps to
make the project that much better. Respond to the feedback and work with your
reviewer(s) to resolve any issues.

Reviewers are responsible for ensuring that each merged PR's commit message
conforms to [conventional commits](https://conventionalcommits.org). This may
mean editing the commit message when you merge the pull request. Alternately,
the reviewer may ask the pull request submitter to amend the commit message of
their initial commit.

## Releases

This repository includes a set of tools for releasing gems. Only maintainers
can perform releases.

### Normal release process

Releases are normally performed using GitHub Actions.

 1. Wait for the CI checks on the latest main branch commit to succeed. The
    release scripts will not run unless the build is green.
 2. In the GitHub UI, go to the `Actions` tab, select the
    `Open release request` workflow, and run the workflow manually using the
    dropdown in the upper right.
     *  Releases must be run from the main branch.
     *  If you leave the `Gems to release` field, blank, and the script will
        find all the gems that have had conventional-commit-tagged changes since
        their last release. Alternately, you can specify which gems to release
        by including their names, space-delimited, in this this field. You can
        optionally append `:<version>` to any gem in the list to specify the
        version to release, or omit the version to let the script decide based
        on conventional commits. You can also use the special name `all` to
        force release of all gems (and even `all:<version>` to release all gems
        with the same version.)
 3. The workflow will analyze the conventional commit messages for the gems to
    release, and will open a _release pull request_. This pull request will
    include the appropriate changes to each gem's version constants, and an
    initial changelog entry for each gem. Note that it is possible to release
    more than one gem using a single release pull request.
 4. You may optionally make further modifications to the pull request branch.
    For example, the workflow will suggest a version number based on semver
    analysis of the conventional commit types, but you can choose to release a
    different version. You might also want to edit the changelog wording.
 5. To trigger the release(s), merge the release pull request. Note that the
    label `release: pending` will have been applied to the pull request when it
    was opened; make sure the label is still there when you merge it.
 6. The automated release script will run automatically, and will release the
    gem(s) once CI has completed. This includes:
     *  For each gem, it will create a release tag and a GitHub release.
     *  It will build and push the gems to rubygems.
     *  If the releases succeed, the script will update the release pull
        request with the results and change its label to `release: complete`.
        If something went wrong, the script will, if possible, report the error
        on the release pull request and change its label to `release: error`.
        It will also attempt to open an issue to alert you to the failure.
 7. If you change your mind and do not want to follow through on a release pull
    request, just close it without merging. (The release scripts will then
    automatically change its label to `release: aborted` for you.)

### Release troubleshooting

If a release fails, the release scripts will attempt to alert you by opening an
issue and/or updating the release pull request. However, you may also need to
review the release logs for the GitHub Actions workflows.

#### About the release workflows

There are four GitHub actions workflows related to releases.

 *  `Open release request` is the main release entrypoint, and is used to open
    a release pull request. If something goes wrong with this process, the logs
    will appear in the workflow run.
 *  `Force release` is generally used only to restart a failed release.
 *  `[release hook] Update open releases` is run on pushes to the main branch,
    and pushes warnings to open release pull requests if you make modifications
    before triggering the release (i.e. because you might need to update the
    changelogs.)
 *  `[release hook] Process release` is the main release automation script and
    is run when a pull request is closed. If it determines that a release pull
    request was merged, it kicks off the release process for the affected gems.
    It also updates the label on a closed release pull request. Finally, it
    deletes release branches when they are no longer being used. If something
    goes wrong with any of these processes, the logs will appear here.

#### Restarting a release

If you've already merged a release pull request and want to retry a failed
release, you can use the `Force release` workflow.

 1. If the release tag has already been created, delete it manually using the
    GitHub UI.
 2. In the GitHub UI, go to the `Actions` tab, select the `Force release`
    workflow, and run it manually.
     *  You must provide the gem name and version explicitly in the fields.
     *  The `Extra flags` field is useful for advanced cases. For example, if
        the GitHub release tag is already created and the gem already pushed to
        Rubygems, but the docs still need to be built, you can pass
        `--only=docs` to perform only that one step. You can also force a
        release even if the build is not green or the version/changelog checks
        are failing, by passing `--skip-checks`. For more details, install the
        `toys` gem and run `toys release perform --help` locally.

#### Running releases locally

It is possible to run the release scripts locally if GitHub Actions is having
problems. You will need to install the `toys` gem first, and you will need the
Rubygems API key for opentelemetry-ruby-contrib. These commands will succeed only if
you have write access to the repository.

To open a release pull request:

```sh
toys release request
```

Pass the `--gems=` flag to provide a list of gems, or omit it to release all
changed gems.

To force-release, assuming the version and changelog are already modified:

```
toys release perform --rubygems-api-key=$API_KEY $GEM_NAME $GEM_VERSION
```

Pass `--help` to either command for details on the options.

### Adding gems

The release configuration is defined in the `.toys/.data/releases.yml` file.
Gems must be listed in this file to be supported by the release process.

To add a gem, add an appropriate entry under the `gems:` section. The `name:`
and `directory:` fields are generally required, as is `version_constant:`.
Some gems will also need to provide `version_rb_path:` if the file path does
not correspond exactly to the gem name.

For releases to succeed, new gems MUST include the following:

 *  The above configuration entry.
 *  The `*.gemspec` file, with the name matching the gem name.
 *  A `version.rb` file in the standard location, or in a location listed in
    the configuration.
 *  A `CHANGELOG.md` file.
 *  A `yard` rake task.

## Dependabot Updates

This repository uses [Dependabot](https://dependabot.com/) to keep dependencies up to date, however there shared development dependencies are often scattered across multiple gems. Dependabot does not currently support the ability to group dependencies for gems in multiple subdirectories, so we use a custom script to bulk update dependencies across all gems.

**Note:** This script uses a version of sed that isn't available on MacOS bash. You'll need to use an ubuntu-linux machine to execute it. One way to accomplish this is to run `docker-compose run app` and execute the script within the container.

E.g. if you want to update Rubocop to version 1.56.1, you would run:

```console

$> bin/update-dependencies rubocop 1.56.1

Review your changes and commit
Press any key to continue

```

This will then run a bulk update on all of the gems in the repository, and then prompt you to review the changes and stage them for a commit:

```console

diff --git a/propagator/ottrace/opentelemetry-propagator-ottrace.gemspec b/propagator/ottrace/opentelemetry-propagator-ottrace.gemspec
index 42c5ecba..74fcc743 100644
--- a/propagator/ottrace/opentelemetry-propagator-ottrace.gemspec
+++ b/propagator/ottrace/opentelemetry-propagator-ottrace.gemspec
@@ -28,7 +28,7 @@ Gem::Specification.new do |spec|
   spec.add_development_dependency 'bundler', '~> 2.4'
   spec.add_development_dependency 'minitest', '~> 5.0'
   spec.add_development_dependency 'rake', '~> 13.0'
-  spec.add_development_dependency 'rubocop', '~> 1.50.0'
+  spec.add_development_dependency 'rubocop', '~> 1.56.1'
   spec.add_development_dependency 'simplecov', '~> 0.22.0'
   spec.add_development_dependency 'yard', '~> 0.9'
   spec.add_development_dependency 'yard-doctest', '~> 0.1.6'
(1/1) Stage this hunk [y,n,q,a,d,e,?]? y

diff --git a/propagator/xray/opentelemetry-propagator-xray.gemspec b/propagator/xray/opentelemetry-propagator-xray.gemspec
index e29acbfc..85622d25 100644
--- a/propagator/xray/opentelemetry-propagator-xray.gemspec
+++ b/propagator/xray/opentelemetry-propagator-xray.gemspec
@@ -31,7 +31,7 @@ Gem::Specification.new do |spec|
   spec.add_development_dependency 'bundler', '~> 2.4'
   spec.add_development_dependency 'minitest', '~> 5.0'
   spec.add_development_dependency 'rake', '~> 13.0'
-  spec.add_development_dependency 'rubocop', '~> 1.50.0'
+  spec.add_development_dependency 'rubocop', '~> 1.56.1'
   spec.add_development_dependency 'simplecov', '~> 0.22.0'
   spec.add_development_dependency 'yard', '~> 0.9'
   spec.add_development_dependency 'yard-doctest', '~> 0.1.6'
(1/1) Stage this hunk [y,n,q,a,d,e,?]? y
```

[cncf-cla]: https://identity.linuxfoundation.org/projects/cncf
[github-draft]: https://github.blog/2019-02-14-introducing-draft-pull-requests/
[kube-github-workflow-pr]: https://github.com/kubernetes/community/blob/master/contributors/guide/github-workflow.md#7-create-a-pull-request
[otel-contributor-guide]: https://github.com/open-telemetry/community/blob/master/CONTRIBUTING.md
[otel-github-workflow]: https://github.com/open-telemetry/community/blob/master/CONTRIBUTING.md#github-workflow
[otel-lib-guidelines]: https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/library-guidelines.md
[otel-specification]: https://github.com/open-telemetry/opentelemetry-specification
