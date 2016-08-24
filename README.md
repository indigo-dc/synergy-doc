

In the current OpenStack implementation, it is only possible to grant fixed quotas to the different user groups (implemented as projects). These resources cannot be exceeded by one group even if there are unused resources allocated to other projects. 

Another issue in the OpenStack implementation regards the management of requests that can't be immediately fullfilled: when there aren’t resources available, new requests are simply rejected. It is then up to the client to later re-issue the request. 

**Synergy** addresses both these issues.

With Synergy the OpenStack administrator can allocate a subset of resources, called *dynamic resources,* to be shared among different projects. Such dynamic resources are not statically allocated with fixed quotas, but are instead shared among multiple projects according to a fair share policy defined by the Cloud administrator, taking also into  account the past usage of such resources.

Synergy provides also a queuing mechanism for the requests that can't be immediately fullfilled: these requests will be served when the relevant resources are available.

Synergy can manage the instantation of both Virtual Machines and containers managed via the nova-docker service.

For what concerns the architecture, **Synergy** is an extensible general purpose management service to be integrated in OpenStack. Its capabilities are implemented by a collection of managers which are specific and independent pluggable tasks, executed periodically, like the cron jobs, or interactively through a RESTful API. Different managers can coexist and they can interact with each other in a loosely coupled way by implementing any even complex business logic.




