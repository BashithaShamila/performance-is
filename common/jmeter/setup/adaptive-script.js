var DUMMY_URL = 'http://localhost:3500';

var onLoginRequest = function(context) {
    executeStep(1, {
        onSuccess: function(context) {
            var user = context.currentKnownSubject;

            // --- Phase 1: Read local claims ---
            var username = user.localClaims['http://wso2.org/claims/username'];
            var givenname = user.localClaims['http://wso2.org/claims/givenname'];
            var lastname = user.localClaims['http://wso2.org/claims/lastname'];

            // --- Phase 2: User lookups ---
            var byUsername = getUniqueUserWithClaimValues(
                {'http://wso2.org/claims/username': username}, context);
            var byGivenname = getUniqueUserWithClaimValues(
                {'http://wso2.org/claims/givenname': givenname}, context);
            var byLastname = getUniqueUserWithClaimValues(
                {'http://wso2.org/claims/lastname': lastname}, context);
            var byUsernameCheck = getUniqueUserWithClaimValues(
                {'http://wso2.org/claims/username': username}, context);

            // --- Phase 3: Async httpPost chain ---

            httpPost(DUMMY_URL + '/dummyCreate',
                { action: "createUser" },
                {"Content-Type": "application/json"},
                {
                    onSuccess: function(context, data) {
                        var user = context.currentKnownSubject;

                        // ✅ FIX: handle both string and object
                        var resp = (typeof data === "string") ? JSON.parse(data) : data;

                        user.localClaims['http://wso2.org/claims/externalid'] = resp.id;

                        httpPost(DUMMY_URL + '/dummyClaims',
                            { action: "getNorthStarClaims" },
                            {"Content-Type": "application/json"},
                            {
                                onSuccess: function(context, data) {
                                    var user = context.currentKnownSubject;

                                    // ✅ FIX: handle both string and object
                                    var c = (typeof data === "string") ? JSON.parse(data) : data;

                                    user.localClaims['http://wso2.org/claims/groups'] = c.groups;
                                    user.localClaims['http://wso2.org/claims/organization'] = c.organization;

                                    user.localClaims['http://wso2.org/claims/entitlements'] = c.entitlements;
                                    user.localClaims['http://wso2.org/claims/givenname'] = 'PerfTestFirst';
                                    user.localClaims['http://wso2.org/claims/lastname'] = 'PerfTestLast';
                                    user.localClaims['http://wso2.org/claims/emailaddress'] = 'perf@test.com';
                                    user.localClaims['http://wso2.org/claims/country'] = 'US';
                                    user.localClaims['http://wso2.org/claims/im'] = 'DEPT-100';
                                    user.localClaims['http://wso2.org/claims/nickname'] = 'DIV-NORTH';
                                    user.localClaims['http://wso2.org/claims/role'] = 'perf_test_user';
                                    user.localClaims['http://wso2.org/claims/telephone'] = '+1234567890';
                                    user.localClaims['http://wso2.org/claims/url'] = 'ORG-GUID-9988776655';
                                    user.localClaims['http://wso2.org/claims/stateorprovince'] = 'WEST';

                                    httpPost(DUMMY_URL + '/dummyCreate',
                                        { action: "assignEntitlements" },
                                        {"Content-Type": "application/json"},
                                        {
                                            onSuccess: function(context, data) {
                                            },
                                            onFail: function(context, data) {
                                            }
                                        }
                                    );
                                },
                                onFail: function(context, data) {
                                }
                            }
                        );
                    },
                    onFail: function(context, data) {
                    }
                }
            );
        },
        onFail: function(context) {
        }
    });
};