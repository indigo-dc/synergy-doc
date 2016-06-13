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
2. (OPTIONAL) If you use the Docker image to build RPM and DEB packages, you should rebuild the image since it depends on `build_env.sh`.
3. Update the changelogs of the RPM and DEB:
  - RPM: use `rpmdeb-bumpspec -c "insert changelog here" -u "Firstname Lastname <email>" path/to/python-synergy-service.spec`.
  - DEB: use `dch -i` inside the package directory.

#### Publish the changes on git
1. Commit these changes.
2. Push them to OpenStack CI.
3. Make a pull-request to the github repository with the latest commits.
4. Once the changes are merge, tag the version in git (in both the OpenStack and Github repositories).

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

### Changes related to INDIGO-DC
#### Openstack version
TODO
#### Operating System support
TODO

## Plugin developement
TODO