var COUNTRY_CLAIM = "http://wso2.org/claims/country";
var EMAIL_CLAIM = "http://wso2.org/claims/emailaddress";

var onLoginRequest = function (context) {
    executeStep(1, {
        onSuccess: function (context) {
            var user = context.currentKnownSubject;
            var REAL_COUNTRY = "Sri Lanka";

            // Read the email once outside the loop — this is a single CTX_PROP read
            var emailValue = user.localClaims[EMAIL_CLAIM];

            // ── Phase 1: getUniqueUserWithClaimValues loop (11 calls) ──────────
            Log.info("Starting Phase 1: getUniqueUserWithClaimValues x11");

            for (var g = 1; g <= 11; g++) {

                // CRITICAL: new claimMap object every iteration
                // Reusing the same object causes PolyglotMap$LazyEntries$ElementsIterator
                // to exhaust on iteration 1 and throw PolyglotException on iteration 2+
                var claimMap = {};
                claimMap[EMAIL_CLAIM] = emailValue;

                var lookedUpUser = getUniqueUserWithClaimValues(claimMap, context);
                var userId = lookedUpUser.localClaims["http://wso2.org/claims/userid"];
                Log.info("getUsers[" + g + "] userid: " + userId);
            }

            Log.info("Phase 1 complete. 11 getUniqueUserWithClaimValues calls done.");

            // ── Phase 2: localClaims read/write loop (2 operations) ──────────
            Log.info("Starting Phase 2: localClaims access x2");

            for (var i = 1; i <= 2; i++) {
                user.localClaims[COUNTRY_CLAIM] = REAL_COUNTRY;
                var countryVerification = user.localClaims[COUNTRY_CLAIM];
                if (i % 10 === 0 || i === 1) {
                    Log.info("Verified Country at iteration " + i + ": " + countryVerification);
                }
            }

            Log.info("Phase 2 complete. 2 localClaims operations done.");
        },
        onFail: function (context) {
            Log.info("Authentication/Test failed.");
        }
    });
};