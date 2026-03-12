Started by user Bhashitha Shamila (Intern)
Running as SYSTEM
[EnvInject] - Loading node environment variables.
[EnvInject] - Preparing an environment for the build.
[EnvInject] - Keeping Jenkins system variables.
[EnvInject] - Keeping Jenkins build variables.
[EnvInject] - Injecting as environment variables the properties content 
JWT_TOKEN_USER_PASSWORD=test_Pswrd01
JWT_TOKEN_CLIENT_SECRET=n7LluuvpsdAyggBQV2TQyiVfKMwa

[EnvInject] - Variables injected successfully.
[EnvInject] - Injecting contributions.
Building remotely on Worker-AWS05 (IS-PERFORMANCE) in workspace /build/jenkins-home/workspace/product-performance-test/is-performance-execution
Run condition [Or] enabling prebuild for step [Copy artifacts from another project]
[Build Cause] check if build was triggered by [TimerTrigger]
[Boolean condition] checking [false] against [^(1|y|yes|t|true|on|run)$] (origin token: ${SEND_NOTIFICATION})
Run condition [Or] preventing perform for step [Copy artifacts from another project]
[is-performance-execution] $ /bin/bash /tmp/jenkins1642723898970985545.sh
WORKSPACE Directory: /build/jenkins-home/workspace/product-performance-test/is-performance-execution

Starting performance test with params:
    IS_PACK_URL: https://github.com/wso2/product-is/releases/download/v7.2.0/wso2is-7.2.0.zip
    DEPLOYMENT: single-node
    CPU_CORES: 4
==========================================================

Downloading IS Pack...
==========================================================

Cloning performance-is repo...
==========================================================
Cloning into 'performance-is'...
Switched to a new branch 'adaptive'
Branch 'adaptive' set up to track remote branch 'adaptive' from 'origin'.
Build Triggered By bashitha@wso2.com
Completed 1.6 KiB/1.6 KiB (15.8 KiB/s) with 1 file(s) remaining
download: s3://performance-is-resources/Key/is-perf-test.pem to ./is-perf-test.pem
Build started by build cause: MANUALTRIGGER

Building project...
==========================================================
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by com.google.inject.internal.cglib.core.$ReflectUtils$1 (file:/usr/share/maven/lib/guice.jar) to method java.lang.ClassLoader.defineClass(java.lang.String,byte[],int,int,java.security.ProtectionDomain)
WARNING: Please consider reporting this to the maintainers of com.google.inject.internal.cglib.core.$ReflectUtils$1
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
[[1;34mINFO[m] Scanning for projects...
[[1;33mWARNING[m] 
[[1;33mWARNING[m] Some problems were encountered while building the effective model for org.wso2:is-performance-singlenode:pom:1.0.0-SNAPSHOT
[[1;33mWARNING[m] 'build.plugins.plugin.version' for org.apache.maven.plugins:maven-clean-plugin is missing. @ line 62, column 21
[[1;33mWARNING[m] 
[[1;33mWARNING[m] It is highly recommended to fix these problems because they threaten the stability of your build.
[[1;33mWARNING[m] 
[[1;33mWARNING[m] For this reason, future Maven versions might no longer support building such malformed projects.
[[1;33mWARNING[m] 
[[1;34mINFO[m] 
[[1;34mINFO[m] [1m-----------------< [0;36morg.wso2:is-performance-singlenode[0;1m >-----------------[m
[[1;34mINFO[m] [1mBuilding IS Performance Single Node 1.0.0-SNAPSHOT[m
[[1;34mINFO[m] [1m--------------------------------[ pom ]---------------------------------[m
[[1;34mINFO[m] 
[[1;34mINFO[m] [1m--- [0;32mmaven-clean-plugin:2.5:clean[m [1m(default-clean)[m @ [36mis-performance-singlenode[0;1m ---[m
[[1;34mINFO[m] Deleting /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/setup (includes = [**/target], excludes = [])
[[1;34mINFO[m] 
[[1;34mINFO[m] [1m--- [0;32mmaven-assembly-plugin:2.2-beta-5:single[m [1m(distribution)[m @ [36mis-performance-singlenode[0;1m ---[m
[[1;34mINFO[m] Reading assembly descriptor: /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/bin.xml
[[1;34mINFO[m] setup/ already added, skipping
[[1;34mINFO[m] setup/ already added, skipping
[[1;34mINFO[m] setup/resources already added, skipping
[[1;34mINFO[m] jmeter/ already added, skipping
[[1;34mINFO[m] Building tar : /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/target/is-performance-singlenode-1.0.0-SNAPSHOT.tar.gz
[[1;34mINFO[m] setup/ already added, skipping
[[1;34mINFO[m] setup/ already added, skipping
[[1;34mINFO[m] setup/resources already added, skipping
[[1;34mINFO[m] jmeter/ already added, skipping
[[1;34mINFO[m] 
[[1;34mINFO[m] [1m--- [0;32mmaven-install-plugin:2.4:install[m [1m(default-install)[m @ [36mis-performance-singlenode[0;1m ---[m
[[1;34mINFO[m] Installing /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/pom.xml to /home/ubuntu/.m2/repository/org/wso2/is-performance-singlenode/1.0.0-SNAPSHOT/is-performance-singlenode-1.0.0-SNAPSHOT.pom
[[1;34mINFO[m] Installing /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/target/is-performance-singlenode-1.0.0-SNAPSHOT.tar.gz to /home/ubuntu/.m2/repository/org/wso2/is-performance-singlenode/1.0.0-SNAPSHOT/is-performance-singlenode-1.0.0-SNAPSHOT.tar.gz
[[1;34mINFO[m] [1m------------------------------------------------------------------------[m
[[1;34mINFO[m] [1;32mBUILD SUCCESS[m
[[1;34mINFO[m] [1m------------------------------------------------------------------------[m
[[1;34mINFO[m] Total time:  2.558 s
[[1;34mINFO[m] Finished at: 2026-03-12T04:54:21Z
[[1;34mINFO[m] [1m------------------------------------------------------------------------[m

Starting test...
==========================================================
./start-performance.sh -k /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -c is-perf-cert -j /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/apache-jmeter-5.3.tgz -n /build/jenkins-home/workspace/product-performance-test/is-performance-execution/wso2is.zip -q bashitha@wso2.com -i c6i.xlarge -t PKCS12 -m mysql -l false -s - -r 50-50 -v PUBLISH -f single-node -k n7LluuvpsdAyggBQV2TQyiVfKMwa -o test_Pswrd01 -z true -d 5 -w 2 -i Adaptive_Script
./start-performance.sh: illegal option -- v
Invalid option: -
May be needed for the perf-test script.

Results will be downloaded to /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/results-2026-03-12--04-54-21

Extracting IS Performance Distribution to /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/results-2026-03-12--04-54-21

Estimating time for performance tests: /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/results-2026-03-12--04-54-21/jmeter/run-performance-tests.sh -t -b mysql -g 1 -a false -r 50-50 -v PUBLISH -f single-node -k n7LluuvpsdAyggBQV2TQyiVfKMwa -o test_Pswrd01 -z true -d 5 -w 2 -i Adaptive_Script
Pseudo-terminal will not be allocated because stdin is not a terminal.
Running tests for concurrency level 50

==========================================================================================
  Scenario Filtering
==========================================================================================
  Mode: PUBLISH
  Include patterns: Adaptive_Script
  Exclude patterns: <none>

--- Applying mode filter: PUBLISH ---
  00-oauth_client_credential_grant | modes=[FULL PUBLISH] | skip=false
  03-oidc_auth_code_redirect_with_consent_retrieve_user_attributes_and_groups | modes=[FULL QUICK] | skip=true
  04-oidc_auth_code_redirect_with_consent_retrieve_user_attributes_groups_and_roles | modes=[FULL QUICK] | skip=true
  05-oidc_auth_code_redirect_without_consent | modes=[FULL QUICK PUBLISH] | skip=false
  06-oidc_auth_code_redirect_without_consent_retrieve_user_attributes | modes=[FULL QUICK PUBLISH] | skip=false
  07-oidc_auth_code_redirect_without_consent_retrieve_user_attributes_and_groups | modes=[FULL QUICK] | skip=true
  08-oidc_auth_code_redirect_without_consent_retrieve_user_attributes_groups_and_roles | modes=[FULL QUICK PUBLISH OIDC_AUTH_CODE_REDIRECT_WITHOUT_CONSENT_UA_GROUPS_ROLES_FLOW] | skip=false
  09-oidc_password_grant | modes=[FULL QUICK PUBLISH] | skip=false
  01-oidc_auth_code_redirect_with_consent | modes=[FULL QUICK PUBLISH] | skip=false
  10-oidc_password_grant_retrieve_user_attributes | modes=[FULL QUICK] | skip=true
  11-oidc_password_grant_retrieve_user_attributes_and_groups | modes=[FULL QUICK] | skip=true
  12-oidc_password_grant_retrieve_user_attributes_groups_and_roles | modes=[FULL QUICK] | skip=true
  13-saml2_sso_redirect_binding | modes=[FULL QUICK PUBLISH] | skip=false
  14-Token_Exchange_Grant | modes=[FULL QUICK PUBLISH] | skip=false
  15-B2B_oidc_auth_code_redirect_with_consent | modes=[B2B] | skip=true
  16-App_Native_Auth | modes=[FULL PUBLISH] | skip=false
  17-Adaptive_Script_RoleBased_Login | modes=[FULL PUBLISH] | skip=false
  02-oidc_auth_code_redirect_with_consent_retrieve_user_attributes | modes=[FULL QUICK] | skip=true

--- Applying include/exclude filter ---
  FILTERED OUT: '00-oauth_client_credential_grant' (was enabled by mode, no include match)
  FILTERED OUT: '05-oidc_auth_code_redirect_without_consent' (was enabled by mode, no include match)
  FILTERED OUT: '06-oidc_auth_code_redirect_without_consent_retrieve_user_attributes' (was enabled by mode, no include match)
  FILTERED OUT: '08-oidc_auth_code_redirect_without_consent_retrieve_user_attributes_groups_and_roles' (was enabled by mode, no include match)
  FILTERED OUT: '09-oidc_password_grant' (was enabled by mode, no include match)
  FILTERED OUT: '01-oidc_auth_code_redirect_with_consent' (was enabled by mode, no include match)
  FILTERED OUT: '13-saml2_sso_redirect_binding' (was enabled by mode, no include match)
  FILTERED OUT: '14-Token_Exchange_Grant' (was enabled by mode, no include match)
  FILTERED OUT: '16-App_Native_Auth' (was enabled by mode, no include match)
  MATCH: '17-Adaptive_Script_RoleBased_Login' =~ 'Adaptive_Script' -> skip=false

--- Final scenario selection ---
  ENABLED: 17-Adaptive_Script_RoleBased_Login (jmx=adaptive/Adaptive_Script_RoleBased_Flow.jmx)
  Total enabled: 1
==========================================================================================

Saving test metadata...
Estimated execution times:
Scenario                                        Combination(s)                                      Estimated Time
17-Adaptive_Script_RoleBased_Login                           1                        8 minute(s) and 40 second(s)
                                   Total                     1                        8 minute(s) and 40 second(s)
Script execution time: 0 second(s)
your key is
/build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem

Preparing cloud formation template...
============================================
random_number: 2999

Validating stack...
============================================
{
    "Parameters": [
        {
            "ParameterKey": "KeyPairName",
            "NoEcho": false,
            "Description": "The private key used to log in to instances through SSH"
        },
        {
            "ParameterKey": "EnableHighConcurrencyMode",
            "DefaultValue": "false",
            "NoEcho": false
        },
        {
            "ParameterKey": "DBInstanceType",
            "DefaultValue": "db.m6i.2xlarge",
            "NoEcho": false
        },
        {
            "ParameterKey": "DBSnapshotId",
            "DefaultValue": "",
            "NoEcho": false,
            "Description": "Snapshot ID to restore the database from"
        },
        {
            "ParameterKey": "SessionDBPassword",
            "NoEcho": true
        },
        {
            "ParameterKey": "DBType",
            "DefaultValue": "mysql",
            "NoEcho": false
        },
        {
            "ParameterKey": "SessionDBUsername",
            "NoEcho": false
        },
        {
            "ParameterKey": "DBPassword",
            "NoEcho": true
        },
        {
            "ParameterKey": "BastionInstanceType",
            "DefaultValue": "c6i.xlarge",
            "NoEcho": false
        },
        {
            "ParameterKey": "SessionDBInstanceType",
            "DefaultValue": "db.m6i.2xlarge",
            "NoEcho": false
        },
        {
            "ParameterKey": "CertificateName",
            "NoEcho": false,
            "Description": "A valid SSL certificate used for HTTPS"
        },
        {
            "ParameterKey": "UserTag",
            "DefaultValue": "user@wso2.com",
            "NoEcho": false,
            "Description": "User tag to be used for tagging AWS resources"
        },
        {
            "ParameterKey": "DBUsername",
            "NoEcho": false
        },
        {
            "ParameterKey": "WSO2InstanceType",
            "DefaultValue": "c6i.xlarge",
            "NoEcho": false
        }
    ],
    "Description": "WSO2 Identity Server single node deployment"
}

Creating stack...
============================================
aws cloudformation create-stack --stack-name is-performance-single-node--2026-03-12--04-54-21--2999     --template-body file://new-single-node.yml --parameters         ParameterKey=CertificateName,ParameterValue=is-perf-cert         ParameterKey=KeyPairName,ParameterValue=is-perf-test         ParameterKey=DBUsername,ParameterValue=wso2carbon         ParameterKey=DBPassword,ParameterValue=wso2carbon         ParameterKey=DBInstanceType,ParameterValue=db.m6i.2xlarge         ParameterKey=DBType,ParameterValue=mysql         ParameterKey=SessionDBUsername,ParameterValue=wso2carbon         ParameterKey=SessionDBPassword,ParameterValue=wso2carbon         ParameterKey=SessionDBInstanceType,ParameterValue=db.m6i.2xlarge         ParameterKey=WSO2InstanceType,ParameterValue=c6i.xlarge         ParameterKey=BastionInstanceType,ParameterValue=c6i.2xlarge         ParameterKey=DBSnapshotId,ParameterValue=         ParameterKey=EnableHighConcurrencyMode,ParameterValue=false         ParameterKey=UserTag,ParameterValue=bashitha@wso2.com     --capabilities CAPABILITY_IAM

Created stack ID: arn:aws:cloudformation:us-east-1:125035497591:stack/is-performance-single-node--2026-03-12--04-54-21--2999/89af0320-1dcf-11f1-9647-0affdacdfdf9

Waiting 10m before polling for cloudformation stack's CREATE_COMPLETE status...

Polling till the stack creation completes...
Stack creation time: 10 minute(s) and 02 second(s)

Getting Bastion Node Public IP...
Bastion Node Public IP: 44.193.139.48

Getting NGinx Instance Private IP...
NGinx Instance Private IP: 10.0.1.187

Getting WSO2 IS Node 1 Private IP...
WSO2 IS Node 1 Private IP: 10.0.1.144

Getting RDS Hostname...
RDS Hostname: wso2isdbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com

Getting Session DB RDS Hostname...
Session DB RDS Hostname: wso2issessiondbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com

Copying files to Bastion node...
============================================
scp -r -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/results-2026-03-12--04-54-21/setup ubuntu@44.193.139.48:/home/ubuntu/
Warning: Permanently added '44.193.139.48' (ECDSA) to the list of known hosts.
scp -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no target/is-performance-*.tar.gz ubuntu@44.193.139.48:/home/ubuntu
scp -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/apache-jmeter-5.3.tgz ubuntu@44.193.139.48:/home/ubuntu/
scp -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no /build/jenkins-home/workspace/product-performance-test/is-performance-execution/wso2is.zip ubuntu@44.193.139.48:/home/ubuntu/wso2is.zip
scp -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem ubuntu@44.193.139.48:/home/ubuntu/private_key.pem
scp -r -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/results-2026-03-12--04-54-21/lib/* ubuntu@44.193.139.48:/home/ubuntu/

Downloading GraalJS sidecar JAR from https://github.com/BashithaShamila/external-graaljs/releases/download/v1.0.0-SNAPSHOT/graaljs-sidecar-1.0.0-SNAPSHOT.jar...
============================================
scp -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no /tmp/graaljs-sidecar.jar ubuntu@44.193.139.48:/home/ubuntu/graaljs-sidecar-1.0.0.jar

Running Bastion Node setup script...
============================================
ssh -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no -t ubuntu@44.193.139.48 sudo ./setup/setup-bastion.sh -n 1 -w 10.0.1.144 -i x.x.x.x -j x.x.x.x -k x.x.x.x -r wso2isdbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -s wso2issessiondbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -l 10.0.1.187
Pseudo-terminal will not be allocated because stdin is not a terminal.

Setting up required files...
============================================

Extracting is performance distribution...
============================================

Running JMeter setup script...
============================================
workspace/setup/setup-jmeter-client.sh -g -k /home/ubuntu/private_key.pem -i /home/ubuntu -c /home/ubuntu -f /home/ubuntu/apache-jmeter-5.3.tgz -a wso2is1 -n 10.0.1.144 -a loadbalancer -n 10.0.1.187 -a rds -n wso2isdbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -a sessionrds -n wso2issessiondbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -w http://search.maven.org/remotecontent?filepath=org/mortbay/jetty/alpn/alpn-boot/8.1.12.v20180117/alpn-boot-8.1.12.v20180117.jar -o /opt/alpnboot/alpnboot.jar -j bzm-parallel
chown: cannot access '/tmp/jmeter.log': No such file or directory
chown: cannot access 'jmeter.log': No such file or directory

Coping files to NGinx instance...
============================================
Warning: Permanently added '10.0.1.187' (ECDSA) to the list of known hosts.

Setting up NGinx...
============================================

Coping files...
============================================

Adding IS IPs to conf file...
============================================
cp: cannot create regular file '/etc/nginx/conf.d/': Not a directory
error 1

Increase Open FD Limit...
============================================

Set soft and hard limit for ubuntu user...
============================================
sed: can't read /etc/nginx/conf.d/is.conf: No such file or directory
fs.file-max = 65535
[Service]
LimitNOFILE=65535

Adding workerconnection to nginx.conf file
============================================
Failed to restart nginx.service: Unit nginx.service not found.
Remote ssh command failed.

Creating databases in RDS...
============================================
ssh -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no -t ubuntu@44.193.139.48 cd /home/ubuntu/ ; unzip -q wso2is.zip ; mv wso2is-* wso2is
Pseudo-terminal will not be allocated because stdin is not a terminal.
ssh -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no -t ubuntu@44.193.139.48 mysql -h wso2isdbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -u wso2carbon -pwso2carbon < /home/ubuntu/workspace/setup/resources/mysql/create_database.sql
Pseudo-terminal will not be allocated because stdin is not a terminal.
mysql: [Warning] Using a password on the command line interface can be insecure.

Creating session database in RDS...
ssh -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no -t ubuntu@44.193.139.48 mysql -h wso2issessiondbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -u wso2carbon -pwso2carbon < /home/ubuntu/workspace/setup/resources/mysql/create_session_database.sql
Pseudo-terminal will not be allocated because stdin is not a terminal.
mysql: [Warning] Using a password on the command line interface can be insecure.

Running IS node 1 setup script...
============================================
ssh -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no -t ubuntu@44.193.139.48 ./setup/setup-is.sh -n 1 -m mysql -c false -a wso2is1 -t PKCS12 -i 10.0.1.144 -w x.x.x.x -j x.x.x.x -k x.x.x.x -r wso2isdbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -s wso2issessiondbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -g true
Pseudo-terminal will not be allocated because stdin is not a terminal.

Copying Is server setup files...
-------------------------------------------
Warning: Permanently added '10.0.1.144' (ECDSA) to the list of known hosts.

Copying GraalJS sidecar JAR...
-------------------------------------------
Working directory: /home/ubuntu
Updated host entries
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
127.0.0.1 ip-10-0-1-144

Updating packages
Hit:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu bionic InRelease
Hit:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu bionic-updates InRelease
Hit:3 http://us-east-1.ec2.archive.ubuntu.com/ubuntu bionic-backports InRelease
Hit:4 https://packages.microsoft.com/ubuntu/18.04/prod bionic InRelease
Hit:5 http://security.ubuntu.com/ubuntu bionic-security InRelease
Reading package lists...

Installing zip package
Reading package lists...
Building dependency tree...
Reading state information...
The following NEW packages will be installed:
  zip
0 upgraded, 1 newly installed, 0 to remove and 300 not upgraded.
Need to get 167 kB of archives.
After this operation, 638 kB of additional disk space will be used.
Get:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu bionic/main amd64 zip amd64 3.0-11build1 [167 kB]
debconf: unable to initialize frontend: Dialog
debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
debconf: falling back to frontend: Readline
debconf: unable to initialize frontend: Readline
debconf: (This frontend requires a controlling tty.)
debconf: falling back to frontend: Teletype
dpkg-preconfigure: unable to re-open stdin: 
Fetched 167 kB in 0s (0 B/s)
Selecting previously unselected package zip.
(Reading database ... 
(Reading database ... 5%
(Reading database ... 10%
(Reading database ... 15%
(Reading database ... 20%
(Reading database ... 25%
(Reading database ... 30%
(Reading database ... 35%
(Reading database ... 40%
(Reading database ... 45%
(Reading database ... 50%
(Reading database ... 55%
(Reading database ... 60%
(Reading database ... 65%
(Reading database ... 70%
(Reading database ... 75%
(Reading database ... 80%
(Reading database ... 85%
(Reading database ... 90%
(Reading database ... 95%
(Reading database ... 100%
(Reading database ... 61285 files and directories currently installed.)
Preparing to unpack .../zip_3.0-11build1_amd64.deb ...
Unpacking zip (3.0-11build1) ...
Setting up zip (3.0-11build1) ...
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...

Installing jq package
Reading package lists...
Building dependency tree...
Reading state information...
The following additional packages will be installed:
  libjq1 libonig4
The following NEW packages will be installed:
  jq libjq1 libonig4
0 upgraded, 3 newly installed, 0 to remove and 300 not upgraded.
Need to get 276 kB of archives.
After this operation, 930 kB of additional disk space will be used.
Get:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu bionic/universe amd64 libonig4 amd64 6.7.0-1 [119 kB]
Get:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu bionic/universe amd64 libjq1 amd64 1.5+dfsg-2 [111 kB]
Get:3 http://us-east-1.ec2.archive.ubuntu.com/ubuntu bionic/universe amd64 jq amd64 1.5+dfsg-2 [45.6 kB]
debconf: unable to initialize frontend: Dialog
debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
debconf: falling back to frontend: Readline
debconf: unable to initialize frontend: Readline
debconf: (This frontend requires a controlling tty.)
debconf: falling back to frontend: Teletype
dpkg-preconfigure: unable to re-open stdin: 
Fetched 276 kB in 0s (6920 kB/s)
Selecting previously unselected package libonig4:amd64.
(Reading database ... 
(Reading database ... 5%
(Reading database ... 10%
(Reading database ... 15%
(Reading database ... 20%
(Reading database ... 25%
(Reading database ... 30%
(Reading database ... 35%
(Reading database ... 40%
(Reading database ... 45%
(Reading database ... 50%
(Reading database ... 55%
(Reading database ... 60%
(Reading database ... 65%
(Reading database ... 70%
(Reading database ... 75%
(Reading database ... 80%
(Reading database ... 85%
(Reading database ... 90%
(Reading database ... 95%
(Reading database ... 100%
(Reading database ... 61299 files and directories currently installed.)
Preparing to unpack .../libonig4_6.7.0-1_amd64.deb ...
Unpacking libonig4:amd64 (6.7.0-1) ...
Selecting previously unselected package libjq1:amd64.
Preparing to unpack .../libjq1_1.5+dfsg-2_amd64.deb ...
Unpacking libjq1:amd64 (1.5+dfsg-2) ...
Selecting previously unselected package jq.
Preparing to unpack .../jq_1.5+dfsg-2_amd64.deb ...
Unpacking jq (1.5+dfsg-2) ...
Setting up libonig4:amd64 (6.7.0-1) ...
Setting up libjq1:amd64 (1.5+dfsg-2) ...
Processing triggers for libc-bin (2.27-3ubuntu1) ...
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
Setting up jq (1.5+dfsg-2) ...

Installing bc package
Reading package lists...
Building dependency tree...
Reading state information...
bc is already the newest version (1.07.1-2).
0 upgraded, 0 newly installed, 0 to remove and 300 not upgraded.

Installing and configuring System Activity Report
Reading package lists...
Building dependency tree...
Reading state information...
The following additional packages will be installed:
  libsensors4
Suggested packages:
  lm-sensors isag
The following NEW packages will be installed:
  libsensors4 sysstat
0 upgraded, 2 newly installed, 0 to remove and 300 not upgraded.
Need to get 324 kB of archives.
After this operation, 1313 kB of additional disk space will be used.
Get:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu bionic-updates/main amd64 libsensors4 amd64 1:3.4.0-4ubuntu0.1 [28.3 kB]
Get:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu bionic-updates/main amd64 sysstat amd64 11.6.1-1ubuntu0.2 [295 kB]
debconf: unable to initialize frontend: Dialog
debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
debconf: falling back to frontend: Readline
debconf: unable to initialize frontend: Readline
debconf: (This frontend requires a controlling tty.)
debconf: falling back to frontend: Teletype
dpkg-preconfigure: unable to re-open stdin: 
Fetched 324 kB in 0s (14.8 MB/s)
Selecting previously unselected package libsensors4:amd64.
(Reading database ... 
(Reading database ... 5%
(Reading database ... 10%
(Reading database ... 15%
(Reading database ... 20%
(Reading database ... 25%
(Reading database ... 30%
(Reading database ... 35%
(Reading database ... 40%
(Reading database ... 45%
(Reading database ... 50%
(Reading database ... 55%
(Reading database ... 60%
(Reading database ... 65%
(Reading database ... 70%
(Reading database ... 75%
(Reading database ... 80%
(Reading database ... 85%
(Reading database ... 90%
(Reading database ... 95%
(Reading database ... 100%
(Reading database ... 61316 files and directories currently installed.)
Preparing to unpack .../libsensors4_1%3a3.4.0-4ubuntu0.1_amd64.deb ...
Unpacking libsensors4:amd64 (1:3.4.0-4ubuntu0.1) ...
Selecting previously unselected package sysstat.
Preparing to unpack .../sysstat_11.6.1-1ubuntu0.2_amd64.deb ...
Unpacking sysstat (11.6.1-1ubuntu0.2) ...
Processing triggers for ureadahead (0.100.0-20) ...
Processing triggers for libc-bin (2.27-3ubuntu1) ...
Processing triggers for systemd (237-3ubuntu10.11) ...
Setting up libsensors4:amd64 (1:3.4.0-4ubuntu0.1) ...
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
Setting up sysstat (11.6.1-1ubuntu0.2) ...
debconf: unable to initialize frontend: Dialog
debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
debconf: falling back to frontend: Readline

Creating config file /etc/default/sysstat with new version
update-alternatives: using /usr/bin/sar.sysstat to provide /usr/bin/sar (sar) in auto mode
Created symlink /etc/systemd/system/multi-user.target.wants/sysstat.service → /lib/systemd/system/sysstat.service.
Processing triggers for libc-bin (2.27-3ubuntu1) ...
Processing triggers for ureadahead (0.100.0-20) ...
Processing triggers for systemd (237-3ubuntu10.11) ...


Running update-is-conf script: ssh -i ~/private_key.pem -o StrictHostKeyChecking=no -t ubuntu@10.0.1.144       ./update-is-conf.sh -n 1 -c false -r wso2isdbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -m mysql -t PKCS12 -s wso2issessiondbinstance2999.cvcrys1zedh5.us-east-1.rds.amazonaws.com -g true
============================================
Pseudo-terminal will not be allocated because stdin is not a terminal.

unzipping is server
-------------------------------------------

changing server name
-------------------------------------------

Changing permission for MySQL connector
-------------------------------------------

Adding MySQL connector to the pack...
-------------------------------------------

Adding deployment toml file to the pack...
-------------------------------------------

Applying basic parameter changes...
-------------------------------------------

Starting WSO2 IS server...
-------------------------------------------

Restarting WSO2 IS server...
-------------------------------------------

Reverting default auto commit to false for the identity db...
-------------------------------------------

Starting external GraalJS sidecar (gRPC on port 50051)...
-------------------------------------------
GraalJS sidecar started with PID: 11457
GraalJS sidecar is running on localhost:50051.

Running performance tests...
============================================
scp -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no run-performance-tests.sh ubuntu@44.193.139.48:/home/ubuntu/workspace/jmeter
ssh -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no -t ubuntu@44.193.139.48 ./workspace/jmeter/run-performance-tests.sh -p 443 -b mysql -g 1 -a false -r 50-50 -v PUBLISH -f single-node -k n7LluuvpsdAyggBQV2TQyiVfKMwa -o test_Pswrd01 -z true -d 5 -w 2 -i Adaptive_Script
Pseudo-terminal will not be allocated because stdin is not a terminal.
Pseudo-terminal will not be allocated because stdin is not a terminal.
Running tests for concurrency level 50

==========================================================================================
  Scenario Filtering
==========================================================================================
  Mode: PUBLISH
  Include patterns: Adaptive_Script
  Exclude patterns: <none>

--- Applying mode filter: PUBLISH ---
  00-oauth_client_credential_grant | modes=[FULL PUBLISH] | skip=false
  03-oidc_auth_code_redirect_with_consent_retrieve_user_attributes_and_groups | modes=[FULL QUICK] | skip=true
  04-oidc_auth_code_redirect_with_consent_retrieve_user_attributes_groups_and_roles | modes=[FULL QUICK] | skip=true
  05-oidc_auth_code_redirect_without_consent | modes=[FULL QUICK PUBLISH] | skip=false
  06-oidc_auth_code_redirect_without_consent_retrieve_user_attributes | modes=[FULL QUICK PUBLISH] | skip=false
  07-oidc_auth_code_redirect_without_consent_retrieve_user_attributes_and_groups | modes=[FULL QUICK] | skip=true
  08-oidc_auth_code_redirect_without_consent_retrieve_user_attributes_groups_and_roles | modes=[FULL QUICK PUBLISH OIDC_AUTH_CODE_REDIRECT_WITHOUT_CONSENT_UA_GROUPS_ROLES_FLOW] | skip=false
  09-oidc_password_grant | modes=[FULL QUICK PUBLISH] | skip=false
  01-oidc_auth_code_redirect_with_consent | modes=[FULL QUICK PUBLISH] | skip=false
  10-oidc_password_grant_retrieve_user_attributes | modes=[FULL QUICK] | skip=true
  11-oidc_password_grant_retrieve_user_attributes_and_groups | modes=[FULL QUICK] | skip=true
  12-oidc_password_grant_retrieve_user_attributes_groups_and_roles | modes=[FULL QUICK] | skip=true
  13-saml2_sso_redirect_binding | modes=[FULL QUICK PUBLISH] | skip=false
  14-Token_Exchange_Grant | modes=[FULL QUICK PUBLISH] | skip=false
  15-B2B_oidc_auth_code_redirect_with_consent | modes=[B2B] | skip=true
  16-App_Native_Auth | modes=[FULL PUBLISH] | skip=false
  17-Adaptive_Script_RoleBased_Login | modes=[FULL PUBLISH] | skip=false
  02-oidc_auth_code_redirect_with_consent_retrieve_user_attributes | modes=[FULL QUICK] | skip=true

--- Applying include/exclude filter ---
  FILTERED OUT: '00-oauth_client_credential_grant' (was enabled by mode, no include match)
  FILTERED OUT: '05-oidc_auth_code_redirect_without_consent' (was enabled by mode, no include match)
  FILTERED OUT: '06-oidc_auth_code_redirect_without_consent_retrieve_user_attributes' (was enabled by mode, no include match)
  FILTERED OUT: '08-oidc_auth_code_redirect_without_consent_retrieve_user_attributes_groups_and_roles' (was enabled by mode, no include match)
  FILTERED OUT: '09-oidc_password_grant' (was enabled by mode, no include match)
  FILTERED OUT: '01-oidc_auth_code_redirect_with_consent' (was enabled by mode, no include match)
  FILTERED OUT: '13-saml2_sso_redirect_binding' (was enabled by mode, no include match)
  FILTERED OUT: '14-Token_Exchange_Grant' (was enabled by mode, no include match)
  FILTERED OUT: '16-App_Native_Auth' (was enabled by mode, no include match)
  MATCH: '17-Adaptive_Script_RoleBased_Login' =~ 'Adaptive_Script' -> skip=false

--- Final scenario selection ---
  ENABLED: 17-Adaptive_Script_RoleBased_Login (jmx=adaptive/Adaptive_Script_RoleBased_Flow.jmx)
  Total enabled: 1
==========================================================================================

Saving test metadata...

Only adaptive scenario enabled — running minimal setup (users + adaptive app only).
==========================================================================================
jmeter -n -t /home/ubuntu/workspace/jmeter/setup/TestData_SCIM2_Add_User.jmx -Jhost=10.0.1.187 -Jport=443 -JtokenIssuer=Default -JnoOfNodes=1 -JuserCount=1000 -l test_data_store/results.jtl

Mar 12, 2026 5:10:36 AM java.util.prefs.FileSystemPreferences$1 run
INFO: Created user preferences directory.
Creating summariser <summary>
Created the tree successfully using /home/ubuntu/workspace/jmeter/setup/TestData_SCIM2_Add_User.jmx
Starting standalone test @ Thu Mar 12 05:10:36 UTC 2026 (1773292236484)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
Warning: Nashorn engine is planned to be removed from a future JDK release
summary =   1002 in 00:00:02 =  656.2/s Avg:     0 Min:     0 Max:    22 Err:  1002 (100.00%)
Tidying up ...    @ Thu Mar 12 05:10:38 UTC 2026 (1773292238263)
... end of run


==========================================================================================
  Adaptive Script App Setup
==========================================================================================
  Script:    /home/ubuntu/workspace/jmeter/setup/setup-adaptive-script-app.sh
  IS host:   10.0.1.187
  IS port:   443
  Employees: 1000 (existing isTestUser_ users)
  Managers:  0 (new dedicated users)
  Admins:    0 (new dedicated users)
  Command:   /home/ubuntu/workspace/jmeter/setup/setup-adaptive-script-app.sh -h 10.0.1.187 -p 443 -u 1000 -m 0 -a 0
==========================================================================================
============================================================
  Adaptive Script App Setup (IS 7.2.x)
  IS: https://10.0.1.187:443
  Existing users as employees: 1000
  Dedicated admin users: 0
  Dedicated manager users: 0
  Dedicated employee users: 0
  Credentials: /home/ubuntu/adaptive_app_creds.csv
  CSV: /home/ubuntu/testdata/role_users.csv
============================================================

Pre-flight: Checking IS connectivity at https://10.0.1.187:443 ...
  ERROR: Cannot connect to IS at https://10.0.1.187:443 (connection refused/timeout).
  Check that IS is running and the load balancer (nginx) is configured.

  ERROR: Adaptive setup script failed with exit code 1
  Check the output above for API errors.
  WARNING: Continuing despite adaptive setup failure — test may fail.
# Starting the performance test
Scenario Name: 17-Adaptive_Script_RoleBased_Login, Duration: 5 m, Concurrent Users: 50
==========================================================================================

Report location is /home/ubuntu/results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users

Cleaning up any previous log files...
Killing All Carbon Servers...
Enabling GC Logs...
JAVA_OPTS: -XX:+PrintGC -XX:+PrintGCDetails -Xloggc:/home/ubuntu/wso2is/repository/logs/gc.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/ubuntu/wso2is/repository/logs/heap-dump.hprof
JVM_MEM_OPTS: -Xms4G -Xmx4G
Restarting identity server...
Waiting 100 seconds...
Finished starting identity server...
Cleaning databases...
Pseudo-terminal will not be allocated because stdin is not a terminal.
Pseudo-terminal will not be allocated because stdin is not a terminal.
Cleaning databases...
mysql: [Warning] Using a password on the command line interface can be insecure.
mysql: [Warning] Using a password on the command line interface can be insecure.

Starting JMeter Client with JVM_ARGS=-Xms2G -Xmx2G  -Xloggc:/home/ubuntu/results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_gc.log 

Running JMeter command: jmeter -n -t ./workspace/jmeter/adaptive/Adaptive_Script_RoleBased_Flow.jmx -Jconcurrency=50 -Jtime=300 -Jhost=10.0.1.187 -Jport=443 -JnoOfNodes=1 -JnoOfBurst=0 -Jdeployment=single-node -JuserCount=1000 -JuseDelay=true -l /home/ubuntu/results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/results.jtl
[0.000s][warning][gc] -Xloggc is deprecated. Will use -Xlog:gc:/home/ubuntu/results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_gc.log instead.
Warning: Nashorn engine is planned to be removed from a future JDK release
Creating summariser <summary>
Created the tree successfully using ./workspace/jmeter/adaptive/Adaptive_Script_RoleBased_Flow.jmx
Starting standalone test @ Thu Mar 12 05:12:22 UTC 2026 (1773292342949)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
Warning: Nashorn engine is planned to be removed from a future JDK release
summary +     46 in 00:00:07 =    6.7/s Avg:     6 Min:     0 Max:    43 Err:    46 (100.00%) Active: 34 Started: 34 Finished: 0
summary +    957 in 00:00:30 =   31.9/s Avg:     0 Min:     0 Max:     3 Err:   957 (100.00%) Active: 50 Started: 50 Finished: 0
summary =   1003 in 00:00:37 =   27.2/s Avg:     0 Min:     0 Max:    43 Err:  1003 (100.00%)
summary +    976 in 00:00:30 =   32.6/s Avg:     0 Min:     0 Max:     1 Err:   976 (100.00%) Active: 50 Started: 50 Finished: 0
summary =   1979 in 00:01:07 =   29.6/s Avg:     0 Min:     0 Max:    43 Err:  1979 (100.00%)
summary +   1004 in 00:00:30 =   33.5/s Avg:     0 Min:     0 Max:     1 Err:  1004 (100.00%) Active: 50 Started: 50 Finished: 0
summary =   2983 in 00:01:37 =   30.8/s Avg:     0 Min:     0 Max:    43 Err:  2983 (100.00%)
summary +    988 in 00:00:30 =   32.9/s Avg:     0 Min:     0 Max:    14 Err:   988 (100.00%) Active: 50 Started: 50 Finished: 0
summary =   3971 in 00:02:07 =   31.3/s Avg:     0 Min:     0 Max:    43 Err:  3971 (100.00%)
summary +    936 in 00:00:30 =   31.2/s Avg:     0 Min:     0 Max:     2 Err:   936 (100.00%) Active: 50 Started: 50 Finished: 0
summary =   4907 in 00:02:37 =   31.3/s Avg:     0 Min:     0 Max:    43 Err:  4907 (100.00%)
summary +    976 in 00:00:30 =   32.5/s Avg:     0 Min:     0 Max:     1 Err:   976 (100.00%) Active: 50 Started: 50 Finished: 0
summary =   5883 in 00:03:07 =   31.5/s Avg:     0 Min:     0 Max:    43 Err:  5883 (100.00%)
summary +   1004 in 00:00:30 =   33.6/s Avg:     0 Min:     0 Max:     1 Err:  1004 (100.00%) Active: 50 Started: 50 Finished: 0
summary =   6887 in 00:03:37 =   31.8/s Avg:     0 Min:     0 Max:    43 Err:  6887 (100.00%)
summary +    998 in 00:00:30 =   33.2/s Avg:     0 Min:     0 Max:     1 Err:   998 (100.00%) Active: 50 Started: 50 Finished: 0
summary =   7885 in 00:04:07 =   31.9/s Avg:     0 Min:     0 Max:    43 Err:  7885 (100.00%)
summary +   1022 in 00:00:30 =   33.9/s Avg:     0 Min:     0 Max:     1 Err:  1022 (100.00%) Active: 50 Started: 50 Finished: 0
summary =   8907 in 00:04:37 =   32.2/s Avg:     0 Min:     0 Max:    43 Err:  8907 (100.00%)
summary +    743 in 00:00:23 =   32.5/s Avg:     0 Min:     0 Max:     1 Err:   743 (100.00%) Active: 0 Started: 50 Finished: 50
summary =   9650 in 00:05:00 =   32.2/s Avg:     0 Min:     0 Max:    43 Err:  9650 (100.00%)
Tidying up ...    @ Thu Mar 12 05:17:23 UTC 2026 (1773292643069)
... end of run

Collecting server metrics for .
Splitting results.jtl file into results-warmup.jtl and results-measurement.jtl.
Warmup Time: 2 MINUTES
Summarization is enabled. Summary statistics will be written to results-warmup-summary.json and results-measurement-summary.json.
Done in 0 min, 0 sec.                           

Zipping JTL files in /home/ubuntu/results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users
  adding: results-measurement.jtl (deflated 98%)
  adding: results-warmup.jtl (deflated 98%)
  adding: results.jtl (deflated 98%)

Collecting server metrics for .
ssh: Could not resolve hostname wso2is: Temporary failure in name resolution
Zipping results directory...
Actual execution times:
WARNING: There were no scenarios to test.
Script execution time: 6 minute(s) and 48 second(s)
Remote ssh command failed.

Downloading results...
============================================
scp -i /build/jenkins-home/workspace/product-performance-test/is-performance-execution/resources/is-perf-test.pem -o StrictHostKeyChecking=no ubuntu@44.193.139.48:/home/ubuntu/results.zip /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/results-2026-03-12--04-54-21/

Creating summary.csv...
============================================
Reading results from results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/results-measurement-summary.json...
Current directory: results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users
Getting summary results for label: 1 Send request to authorize end point...
WARNING: File missing! results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/wso2is_gc.log
Reading results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_gc.log
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
WARNING: File missing! results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/wso2is_loadavg.txt
Reading results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_loadavg.txt
Getting summary results for label: 2 Common Auth Login HTTP Request...
WARNING: File missing! results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/wso2is_gc.log
Reading results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_gc.log
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
WARNING: File missing! results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/wso2is_loadavg.txt
Reading results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_loadavg.txt
Getting summary results for label: 3 Get Authorization Code...
WARNING: File missing! results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/wso2is_gc.log
Reading results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_gc.log
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
WARNING: File missing! results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/wso2is_loadavg.txt
Reading results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_loadavg.txt
Getting summary results for label: 4 Get access token...
WARNING: File missing! results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/wso2is_gc.log
Reading results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_gc.log
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
grep: /tmp/gc.txt: No such file or directory
WARNING: File missing! results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/wso2is_loadavg.txt
Reading results/17-Adaptive_Script_RoleBased_Login/4G_heap/50_users/jmeter_loadavg.txt
Wrote summary statistics to summary.csv.
Creating summary results markdown file...

Done.

Saving stack events to /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance-is/single-node/results-2026-03-12--04-54-21/stack-events.json

Deleting the stack: arn:aws:cloudformation:us-east-1:125035497591:stack/is-performance-single-node--2026-03-12--04-54-21--2999/89af0320-1dcf-11f1-9647-0affdacdfdf9

Polling till the stack deletion completes...
Stack deletion time: 4 minute(s) and 02 second(s)
Script execution time: 27 minute(s) and 08 second(s)
Completed 256.0 KiB/5.1 MiB (4.0 MiB/s) with 9 file(s) remaining
Completed 512.0 KiB/5.1 MiB (7.9 MiB/s) with 9 file(s) remaining
Completed 768.0 KiB/5.1 MiB (11.1 MiB/s) with 9 file(s) remaining
Completed 1.0 MiB/5.1 MiB (14.1 MiB/s) with 9 file(s) remaining  
Completed 1.2 MiB/5.1 MiB (16.8 MiB/s) with 9 file(s) remaining  
Completed 1.5 MiB/5.1 MiB (19.7 MiB/s) with 9 file(s) remaining  
Completed 1.8 MiB/5.1 MiB (22.7 MiB/s) with 9 file(s) remaining  
Completed 2.0 MiB/5.1 MiB (25.5 MiB/s) with 9 file(s) remaining  
Completed 2.2 MiB/5.1 MiB (28.0 MiB/s) with 9 file(s) remaining  
Completed 2.5 MiB/5.1 MiB (27.8 MiB/s) with 9 file(s) remaining  
Completed 2.8 MiB/5.1 MiB (29.5 MiB/s) with 9 file(s) remaining  
Completed 3.0 MiB/5.1 MiB (31.5 MiB/s) with 9 file(s) remaining  
Completed 3.2 MiB/5.1 MiB (32.7 MiB/s) with 9 file(s) remaining  
upload: results-2026-03-12--04-54-21/results.zip to s3://performance-is-resources/Results/4448/results.zip
Completed 3.2 MiB/5.1 MiB (32.7 MiB/s) with 8 file(s) remaining
Completed 3.2 MiB/5.1 MiB (32.2 MiB/s) with 8 file(s) remaining
upload: results-2026-03-12--04-54-21/summary.csv to s3://performance-is-resources/Results/4448/summary.csv
Completed 3.2 MiB/5.1 MiB (32.2 MiB/s) with 7 file(s) remaining
Completed 3.4 MiB/5.1 MiB (34.5 MiB/s) with 7 file(s) remaining
Completed 3.6 MiB/5.1 MiB (35.3 MiB/s) with 7 file(s) remaining
upload: results-2026-03-12--04-54-21/lib/mssql-jdbc-12.8.1.jre11.jar to s3://performance-is-resources/Results/4448/lib/mssql-jdbc-12.8.1.jre11.jar
Completed 3.6 MiB/5.1 MiB (35.3 MiB/s) with 6 file(s) remaining
Completed 3.8 MiB/5.1 MiB (37.7 MiB/s) with 6 file(s) remaining
Completed 4.1 MiB/5.1 MiB (39.3 MiB/s) with 6 file(s) remaining
Completed 4.3 MiB/5.1 MiB (40.6 MiB/s) with 6 file(s) remaining
Completed 4.6 MiB/5.1 MiB (42.8 MiB/s) with 6 file(s) remaining
Completed 4.8 MiB/5.1 MiB (44.6 MiB/s) with 6 file(s) remaining
Completed 4.9 MiB/5.1 MiB (43.6 MiB/s) with 6 file(s) remaining
upload: results-2026-03-12--04-54-21/stack-events.json to s3://performance-is-resources/Results/4448/stack-events.json
Completed 4.9 MiB/5.1 MiB (43.6 MiB/s) with 5 file(s) remaining
Completed 4.9 MiB/5.1 MiB (40.7 MiB/s) with 5 file(s) remaining
upload: results-2026-03-12--04-54-21/summary.md to s3://performance-is-resources/Results/4448/summary.md
Completed 4.9 MiB/5.1 MiB (40.7 MiB/s) with 4 file(s) remaining
Completed 4.9 MiB/5.1 MiB (40.6 MiB/s) with 4 file(s) remaining
upload: results-2026-03-12--04-54-21/summary/summary-modifier.py to s3://performance-is-resources/Results/4448/summary/summary-modifier.py
Completed 4.9 MiB/5.1 MiB (40.6 MiB/s) with 3 file(s) remaining
Completed 4.9 MiB/5.1 MiB (38.7 MiB/s) with 3 file(s) remaining
upload: results-2026-03-12--04-54-21/summary-original.csv to s3://performance-is-resources/Results/4448/summary-original.csv
Completed 4.9 MiB/5.1 MiB (38.7 MiB/s) with 2 file(s) remaining
Completed 5.0 MiB/5.1 MiB (29.8 MiB/s) with 2 file(s) remaining
upload: results-2026-03-12--04-54-21/lib/postgresql-42.7.4.jar to s3://performance-is-resources/Results/4448/lib/postgresql-42.7.4.jar
Completed 5.0 MiB/5.1 MiB (29.8 MiB/s) with 1 file(s) remaining
Completed 5.1 MiB/5.1 MiB (27.2 MiB/s) with 1 file(s) remaining
upload: results-2026-03-12--04-54-21/lib/mysql-connector-j-8.0.33.jar to s3://performance-is-resources/Results/4448/lib/mysql-connector-j-8.0.33.jar
==========================================================
Creating performance comparison CSV file...
==========================================================
Refreshing access token...
Downloading benchmark data...
Benchmark data downloaded to /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/benchmark.csv
Python 3.8.10
pip 20.0.2 from /usr/lib/python3/dist-packages/pip (python 3.8)
Requirement already satisfied: pandas in /home/ubuntu/.local/lib/python3.8/site-packages (2.0.3)
Requirement already satisfied: tzdata>=2022.1 in /home/ubuntu/.local/lib/python3.8/site-packages (from pandas) (2024.2)
Requirement already satisfied: numpy>=1.20.3; python_version < "3.10" in /home/ubuntu/.local/lib/python3.8/site-packages (from pandas) (1.24.2)
Requirement already satisfied: pytz>=2020.1 in /home/ubuntu/.local/lib/python3.8/site-packages (from pandas) (2024.2)
Requirement already satisfied: python-dateutil>=2.8.2 in /home/ubuntu/.local/lib/python3.8/site-packages (from pandas) (2.9.0.post0)
Requirement already satisfied: six>=1.5 in /usr/lib/python3/dist-packages (from python-dateutil>=2.8.2->pandas) (1.14.0)
Requirement already satisfied: gspread in /home/ubuntu/.local/lib/python3.8/site-packages (6.1.4)
Requirement already satisfied: oauth2client in /home/ubuntu/.local/lib/python3.8/site-packages (4.1.3)
Requirement already satisfied: google-auth>=1.12.0 in /home/ubuntu/.local/lib/python3.8/site-packages (from gspread) (2.37.0)
Requirement already satisfied: google-auth-oauthlib>=0.4.1 in /home/ubuntu/.local/lib/python3.8/site-packages (from gspread) (1.2.1)
Requirement already satisfied: pyasn1-modules>=0.0.5 in /usr/lib/python3/dist-packages (from oauth2client) (0.2.1)
Requirement already satisfied: six>=1.6.1 in /usr/lib/python3/dist-packages (from oauth2client) (1.14.0)
Requirement already satisfied: pyasn1>=0.1.7 in /usr/lib/python3/dist-packages (from oauth2client) (0.4.2)
Requirement already satisfied: rsa>=3.1.4 in /home/ubuntu/.local/lib/python3.8/site-packages (from oauth2client) (4.9)
Requirement already satisfied: httplib2>=0.9.1 in /usr/lib/python3/dist-packages (from oauth2client) (0.14.0)
Requirement already satisfied: cachetools<6.0,>=2.0.0 in /home/ubuntu/.local/lib/python3.8/site-packages (from google-auth>=1.12.0->gspread) (5.5.0)
Requirement already satisfied: requests-oauthlib>=0.7.0 in /home/ubuntu/.local/lib/python3.8/site-packages (from google-auth-oauthlib>=0.4.1->gspread) (2.0.0)
Requirement already satisfied: oauthlib>=3.0.0 in /usr/lib/python3/dist-packages (from requests-oauthlib>=0.7.0->google-auth-oauthlib>=0.4.1->gspread) (3.1.0)
Requirement already satisfied: requests>=2.0.0 in /usr/lib/python3/dist-packages (from requests-oauthlib>=0.7.0->google-auth-oauthlib>=0.4.1->gspread) (2.22.0)
Comparison saved to: /build/jenkins-home/workspace/product-performance-test/is-performance-execution/workspace/performance_comparison.csv
Archiving artifacts
Started calculate disk usage of build
Finished Calculation of disk usage of build in 0 seconds
Started calculate disk usage of workspace
Finished Calculation of disk usage of workspace in 0 seconds
Finished: SUCCESS