+++
title = "MongoDB Cheat Sheet"
date = 2021-04-09 13:59:07
[taxonomies]
tags = ["mongodb"]
+++

## MongoRestore

``` bash
$ tldr mongorestore
Local data is older than two weeks, use --update to update it.


mongorestore

Utility to import a collection or database from a binary dump into a MongoDB instance.
More information: <https://docs.mongodb.com/manual/reference/program/mongorestore>.

- Import a bson data dump from a directory to a MongoDB database:
    mongorestore --db database_name path/to/directory

- Import a bson data dump from a directory to a given database in a MongoDB server host, running at a given port, with user authentication (user will be prompted for password):
    mongorestore --host database_host:port --db database_name --username username path/to/directory --password

- Import a collection from a bson file to a MongoDB database:
    mongorestore --db database_name path/to/file

- Import a collection from a bson file to a given database in a MongoDB server host, running at a given port, with user authentication (user will be prompted for password):
    mongorestore --host database_host:port --db database_name --username username path/to/file --password

```

``` bash
$ mongorestore --host localhost:27017 --db database --username root --password pass12345 path/to/bson/file
2021-04-09T13:52:15.562+0800    error connecting to host: could not connect to server: connection() : auth error: sasl conversation error: unable to authenticate using mechanism "SCRAM-SHA-1": (AuthenticationFailed) Authentication failed.
```

``` bash
$ mongorestore --host localhost:27017 --db database --authenticationDatabase admin --username root --password pass12345 path/to/bson/file
2021-04-09T13:53:45.918+0800    checking for collection data in path/to/bson/file
2021-04-09T13:53:45.937+0800    reading metadata for testing.meta from path/to/bson/file.json
2021-04-09T13:53:45.958+0800    restoring testing.meta from path/to/bson/file
2021-04-09T13:53:48.908+0800    [........................]  testing.meta  3.40MB/222MB  (1.5%)
2021-04-09T13:53:51.908+0800    [........................]  testing.meta  6.95MB/222MB  (3.1%)
2021-04-09T13:53:54.908+0800    [#.......................]  testing.meta  10.5MB/222MB  (4.7%)
2021-04-09T13:53:57.908+0800    [#.......................]  testing.meta  14.0MB/222MB  (6.3%)
2021-04-09T13:54:00.908+0800    [#.......................]  testing.meta  18.1MB/222MB  (8.1%)
2021-04-09T13:54:03.908+0800    [##......................]  testing.meta  22.2MB/222MB  (10.0%)
2021-04-09T13:54:06.908+0800    [##......................]  testing.meta  26.0MB/222MB  (11.7%)
2021-04-09T13:54:09.908+0800    [###.....................]  testing.meta  29.9MB/222MB  (13.5%)
2021-04-09T13:54:12.908+0800    [###.....................]  testing.meta  33.9MB/222MB  (15.3%)
2021-04-09T13:54:15.908+0800    [####....................]  testing.meta  38.0MB/222MB  (17.1%)
2021-04-09T13:54:18.908+0800    [####....................]  testing.meta  42.0MB/222MB  (18.9%)
2021-04-09T13:54:21.908+0800    [####....................]  testing.meta  46.1MB/222MB  (20.8%)
2021-04-09T13:54:24.908+0800    [#####...................]  testing.meta  50.2MB/222MB  (22.6%)
2021-04-09T13:54:27.908+0800    [#####...................]  testing.meta  54.4MB/222MB  (24.5%)
2021-04-09T13:54:30.908+0800    [######..................]  testing.meta  61.2MB/222MB  (27.6%)
2021-04-09T13:54:33.908+0800    [#######.................]  testing.meta  68.2MB/222MB  (30.7%)
2021-04-09T13:54:36.908+0800    [########................]  testing.meta  75.2MB/222MB  (33.9%)
2021-04-09T13:54:39.908+0800    [########................]  testing.meta  82.3MB/222MB  (37.1%)
2021-04-09T13:54:42.908+0800    [#########...............]  testing.meta  89.3MB/222MB  (40.2%)
2021-04-09T13:54:45.908+0800    [##########..............]  testing.meta  96.1MB/222MB  (43.3%)
2021-04-09T13:54:48.908+0800    [###########.............]  testing.meta  103MB/222MB  (46.4%)
2021-04-09T13:54:51.908+0800    [###########.............]  testing.meta  110MB/222MB  (49.5%)
2021-04-09T13:54:54.908+0800    [############............]  testing.meta  117MB/222MB  (52.7%)
2021-04-09T13:54:57.908+0800    [#############...........]  testing.meta  124MB/222MB  (55.8%)
2021-04-09T13:55:00.908+0800    [##############..........]  testing.meta  131MB/222MB  (58.9%)
2021-04-09T13:55:03.908+0800    [##############..........]  testing.meta  138MB/222MB  (62.1%)
2021-04-09T13:55:06.908+0800    [###############.........]  testing.meta  145MB/222MB  (65.2%)
2021-04-09T13:55:09.908+0800    [################........]  testing.meta  152MB/222MB  (68.3%)
2021-04-09T13:55:12.908+0800    [#################.......]  testing.meta  159MB/222MB  (71.5%)
2021-04-09T13:55:15.908+0800    [#################.......]  testing.meta  166MB/222MB  (74.7%)
2021-04-09T13:55:18.908+0800    [##################......]  testing.meta  173MB/222MB  (77.9%)
2021-04-09T13:55:21.908+0800    [###################.....]  testing.meta  180MB/222MB  (81.0%)
2021-04-09T13:55:24.908+0800    [####################....]  testing.meta  187MB/222MB  (84.2%)
2021-04-09T13:55:27.908+0800    [####################....]  testing.meta  194MB/222MB  (87.3%)
2021-04-09T13:55:30.908+0800    [#####################...]  testing.meta  201MB/222MB  (90.5%)
2021-04-09T13:55:33.908+0800    [######################..]  testing.meta  208MB/222MB  (93.6%)
2021-04-09T13:55:36.908+0800    [#######################.]  testing.meta  215MB/222MB  (96.8%)
2021-04-09T13:55:39.905+0800    [########################]  testing.meta  222MB/222MB  (100.0%)
2021-04-09T13:55:39.905+0800    no indexes to restore
2021-04-09T13:55:39.907+0800    finished restoring testing.meta (384247 documents, 0 failures)
2021-04-09T13:55:39.907+0800    384247 document(s) restored successfully. 0 document(s) failed to restore.
```
