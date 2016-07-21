# Developer documentation

## Release management
Synergy is made of two packages:

- *synergy-service*: the main package
- *synergy-scheduler-manager*: plugin for *synergy-service* that adds the scheduler functionality. **This package depends on synergy-service**..

### Making a new release for *synergy-service*
#### Set the version
1. Change the version in
  - `setup.cfg`
  - `packaging/docker/build_env.sh`
2. *(OPTIONAL)* If you use the Docker image to build RPM and DEB packages, you should rebuild the image since it depends on `build_env.sh`.
3. Update the changelogs of the RPM and DEB:
  - RPM: edit the spec file and set ` Release` to `0%{?dist}` and `Version` to the new version number, then use `rpmdev-bumpspec -c "insert changelog here" -u "Firstname Lastname <email>" path/to/python-synergy-service.spec`.
  - DEB: use `dch -i` inside the package directory.

#### Publish the changes on git
1. Commit these changes.
2. Push them to OpenStack CI, wait for it to be merged.
3. Make a pull-request to the github repository with the latest commits.
4. Once the changes are merged, tag the version in git (Github repository).

#### Package the new version
1. Build the RPM and DEB packages.
2. Publish the RPM and DEB packages. If the INDIGO-DC repository is set up, hand them to WP3. Otherwise, make a release on Github and attach the RPM and DEB packages to it.
3. Build the python package with:
  ```
  python setup.py bdist_wheel
  ```
  and upload it to PyPI:
  ```
  twine upload dist/PACKAGE
  ```
  see [Python packaging](https://packaging.python.org/en/latest/distributing/) for more info.
  
#### Update dependencies
For all the packages that depend on *synergy-service*: update the `requirements.txt` with the new version of *synergy-service*.

### Making a new release for *synergy-scheduler-manager*
1. Change the version in `setup.cfg` and add changelog for RPM and DEB (see the [synergy-service way](#set-the-version) for details).
2. Publish the changes on git (see the [synergy-service way](#publish-the-changes-on-git) for details).
3. Package the new version (see the [synergy-service way](#package-the-new-version) for details).

### Changes related to INDIGO-DC
#### Openstack version
As of 2016-06-13, the supported OpenStack version by INDIGO-DC is *Liberty*.
If this changes in the future, one should update the Dockerfiles used for packaging.
#### Operating System support
As of 2016-06-13, the support OS by INDIGO-DC are CentOS 7 and Ubuntu 14.04.
If this changes, one should update the Dockerfiles used for packaging accordingly.

## Plugin developement
TODO