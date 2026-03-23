var DUMMY_SERVICE_URL = "http://localhost:3500";

var onLoginRequest = function(context) {
    executeStep(1, {
        onSuccess: function (context) {
            // BOUNDARY 1
            var initialUser = context.currentKnownSubject;
            Log.info("[PERF-TEST] [HOP 0] Starting Automated Flow for user: " + initialUser.username);

            httpPost(DUMMY_SERVICE_URL + "/dummyCreate", 
                {"username": initialUser.username}, 
                {"Accept": "application/json"}, 
                {
                    onSuccess: function(context, createResponse) {
                        // BOUNDARY 2
                        var step1User = context.currentKnownSubject;
                        
                        // LOG FULL PAYLOAD 1 (Safe Java Map concatenation)
                        Log.info("[PERF-TEST] [HOP 1] /dummyCreate FULL response: \n" + createResponse);
                        
                        var extId = createResponse.id;
                        step1User.localClaims["http://wso2.org/claims/externalid"] = extId;
                        Log.info("[PERF-TEST] [HOP 1] Stashed external ID in localClaims for: " + step1User.username);
                        
                        // ASYNC YIELD (Replacing prompt)
                        Log.info("[PERF-TEST] [HOP 2] Initiating artificial polling delay...");
                        httpPost(DUMMY_SERVICE_URL + "/dummyCreate", 
                            {"username": step1User.username, "action": "polling_delay"}, 
                            {"Accept": "application/json"}, 
                            {
                                onSuccess: function(context, waitResponse) {
                                    // BOUNDARY 3
                                    var step2User = context.currentKnownSubject;
                                    var step2Username = step2User.username; 
                                    
                                    // LOG FULL PAYLOAD 2 (Safe Java Map concatenation)
                                    Log.info("[PERF-TEST] [HOP 2] Polling delay completed. FULL response: \n" + waitResponse);
                                    
                                    Log.info("[PERF-TEST] [HOP 3] Fetching massive claims payload...");
                                    httpPost(DUMMY_SERVICE_URL + "/dummyClaims", 
                                        {"username": step2Username}, 
                                        {"Accept": "application/json"}, 
                                        {
                                            onSuccess: function(context, claimData) {
                                                // BOUNDARY 4
                                                var finalUser = context.currentKnownSubject;
                                                
                                                // LOG FULL PAYLOAD 3 (The massive one - Safe Java Map concatenation)
                                                Log.info("[PERF-TEST] [HOP 3] /dummyClaims FULL massive payload received: \n" + claimData);
                                                
                                                // Apply massive payload
                                                finalUser.localClaims["http://wso2.org/claims/entitlements"] = claimData.entitlements;
                                                finalUser.localClaims["http://wso2.org/claims/organization"] = claimData.organization;
                                                finalUser.localClaims["http://wso2.org/claims/groups"] = claimData.groups;
                                                
                                                Log.info("[PERF-TEST] [DONE] Completed automated multi-stage pipeline successfully for: " + finalUser.username);
                                            },
                                            onFail: function(context, data) {
                                                Log.error("[PERF-TEST] [ERROR] Dummy claims fetch failed");
                                                sendError(DUMMY_SERVICE_URL, {'statusMsg': 'Claims fetch failed'});
                                            }
                                        });
                                },
                                onFail: function(context, data) {
                                    Log.error("[PERF-TEST] [ERROR] Dummy wait simulation failed");
                                    sendError(DUMMY_SERVICE_URL, {'statusMsg': 'Wait state failed'});
                                }
                            });
                    },
                    onFail: function(context, data) {
                        Log.error("[PERF-TEST] [ERROR] Dummy user creation failed");
                        sendError(DUMMY_SERVICE_URL, {'statusMsg': 'Creation service unreachable'});
                    }
                });
        }
    });
};