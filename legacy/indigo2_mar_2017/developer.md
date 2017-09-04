# Developer documentation

## Workflow
We use [PBR](http://docs.openstack.org/developer/pbr/) to manage part of the release workflow.

When a developer makes a commit, it should include a `Sem-Ver` line in it indicating the semantic versioning level of the change. By default, this change is `bugfix`. Other levels are: `feature`, `api-break` and `deprecation`.

Example of a commit using `Sem-Ver`: https://review.openstack.org/#/c/384381/3//COMMIT_MSG.

## Release management
Synergy is made of two packages:

- *synergy-service*: the main package
- *synergy-scheduler-manager*: plugin for *synergy-service* that adds the scheduler functionality. **This package depends on synergy-service**.

### Making a new release for *synergy-service*
The idea when making a release for a synergy package is to do it in a *single commit*. This way, we can easily go to this commit and package for that specific version.

#### Get the ChangeLog
Make sure your local repository is up to date with `git pull`.
Then, use `python setup.py bdist_wheel` to
- automatically update the `ChangeLog` and `AUTHORS` files.
- get the new version number: the name of the resulting wheel package will be something like `synergy_service-1.3.0.dev18-py2-none-any.whl`, here `1.3.0` is the new version number that respects [semver](http://semver.org).

#### Update the debian and RPM changelogs
Use the previously generated `ChangeLog` to update the changelog for the Debian and RPM packages. Don't forget to update the synergy version in these files!

For debian, edit the file `packaging/debian/changelog` and add a new entry corresponding to the new version.
Note: you can get a correctly formatted date by using the command `date -R`.

For RPM, edit the file `packaging/rpm/python-synergy.spec`.
You will have to edit the `Version: ` line, as well as adding an entry below the `%changelog` line.
Note: if you are using an \*EL system, you can use the `rpmdev-bumpspec` command.

#### Test packaging for debian and RPM
Use docker to test the packaging for debian and RPM (see `packaging/README.md` for instructions). Don't forget to add `-e "PKG_VERSION=x.y.z"` to test for the new x.y.z version.

Note that the packages generated at this stage are *dev* packages and should not be provided to users as they will cause problems when upgrading.

#### Commit and submit to OpenStack CI
Make a single commit containing the changes to the debian and RPM packaging for the making of the new release. This way it is easy to rebuild the package for old version.

Go to the next step once the commit is merged.

#### Tag the commit
Once the release commit has been merged into `master`, tag it with git.
Note: you *must* make a *signed* and *annotated* tag, otherwise gerrit won't accept it.

After that, submit it to gerrit: `git push gerrit x.y.z`. This will automatically trigger the publication of the python wheel package to PyPI.

#### Packaging
Now that the work has been commited and tagged, we can make proper system packages.
Read the file `packaging/README.md` for instructions, the easiest method for packaging is using Docker.

#### Synchronize to Indigo GitHub repository
Try to synchronize the commits after each release:
- on your local repo, create a new branch that contains the release commit: `git checkout -b release-x.y.z`
- send this to GitHub (you need to have setup the GitHub remote first): `git push github release-x.y.z`
- on GitHub, create a new pull request with the new branch `release-x.y.z`
- wait for the automatic tests to run and pass, then merge the PR into master.

After that, you can manually add the debian and RPM packages to the github release page.

### Making a new release for *synergy-scheduler-manager*
Same process as *synergy-service* above, expect that you need to do the extra step *Update dependencies*:

#### Update dependencies
For all the packages that depend on *synergy-service*: update the `requirements.txt` with the new version of *synergy-service*.

### Changes related to INDIGO-DC
#### Openstack version
As of 2017-08-08, the supported OpenStack version by INDIGO-DC is *Newton*.
If this changes in the future, one should update the Dockerfiles used for packaging.

#### Operating System support
As of 2017-08-08, the support OS by INDIGO-DC are CentOS 7 and Ubuntu 16.04.
If this changes, one should update the Dockerfiles used for packaging accordingly.

## Plugin developement
TODO
