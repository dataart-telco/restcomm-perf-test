# restcomm-perf-test

This script deploys test env to aws or openstack

It uses:

1. `docker-machine`: for provision 
2. `collectd`: for monitoring. clients and server.
3. `ivrapp`: simple backend app to provide menu, gather digits, provide request statistics. it accepts '5' digit only.

We support 3 env types

1. local
2. aws
3. openstack

#### bootstrap aws env

1. create `.aws_credentilas` file. There are example: `.aws_credentials_example`
2. run `install.sh`

#### bootstrap openstack env

1. create `.openstack_credentials` file. There are example: `.openstack_credentials_example`
2. run `install.sh`

#### bootstrap local env

1. it's `default` env, but it doesn't support `collectd` now
2. to run `local` please remove `.aws_credentilas` and `.openstack_credentials`
3. run `install.sh`

#### Start test

When env is ready you can start test. 

Please use `start_test.sh`

it will execute test scenario from `sipp-test` folder on remote machine. 

#### Test results

When test is completed it will download test results to `results` folder

Script collects the following information:

1. sipp test result and logs
2. ivrapp stats - `ivr_stat.txt`
3. machines metrics - a set of png files.
4. perfcorder data
