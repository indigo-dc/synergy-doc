# Developer documentation

## Release management
Synergy is made of two packages:

- *synergy-service*: the main package
- *synergy-scheduler-manager*: plugin for *synergy-service* that adds the scheduler functionality. **This package depends on synergy-service**..

### Making a new release for *synergy-service*
1. Change the version in
  - `setup.cfg`
  - `packaging/docker/build_env.sh`
2. Update the changelogs of the RPM and DEB:
  - RPM: use `rpmdeb-bumpspec -c "insert changelog here" -u "Firstname Lastname <email>" path/to/python-synergy-service.spec`.
  - DEB: use `dch -i` inside the package directory.
3. Commit these changes.
4. Make a pull-request to the github repository with the latest commits.
5. 

### Changes related to INDIGO-DC
#### Openstack version
TODO
#### Operating System support
TODO

## Plugin developement
TODO