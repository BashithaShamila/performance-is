var COUNTRY_CLAIM = "http://wso2.org/claims/country";

var onLoginRequest = function (context) {
    executeStep(1, {
        onSuccess: function (context) {
            var user = context.currentKnownSubject;
            var REAL_COUNTRY = "Sri Lanka";
            
            // 44 total communications (11 original points * 4)
            var targetCount = 44;

            Log.info("Starting Perf Test: 4x Scaling. Total Round-trips: " + targetCount);

            for (var i = 1; i <= targetCount; i++) {
                
                // 1. DATA WRITE: Crossing JS -> Java
                // We set the real claim value
                user.localClaims[COUNTRY_CLAIM] = REAL_COUNTRY;
                
                // 2. DATA READ: Crossing Java -> JS
                // We retrieve the real claim value
                var countryVerification = user.localClaims[COUNTRY_CLAIM];
                
                // 3. LOGGING: Bridge Overhead
                // Log.info also crosses the host boundary to reach the Java logger
                if (i % 10 === 0 || i === 1) {
                    Log.info("Verified Country at iteration " + i + ": " + countryVerification);
                }
            }

            Log.info("Perf test complete. 44 operations processed using real claim URIs.");
        },
        onFail: function (context) {
            Log.info("Authentication/Test failed.");
        }
    });
};