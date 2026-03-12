var rolesToStepUp = ['admin', 'manager'];

var onLoginRequest = function(context) {
    executeStep(1, {
        onSuccess: function(context) {
            var hasAdminOrManager = false;
            try {
                // Determine if user has required roles for step-up auth
                hasAdminOrManager = hasAnyOfTheRolesV2(context, rolesToStepUp);
            } catch(e) {
                Log.info('[TEST] Step 2 Role Check ERROR: ' + e.message);
            }

            if (hasAdminOrManager) {
                Log.info('[TEST] Admin/Manager detected. Triggering Step 2.');

                executeStep(2, {
                    onSuccess: function(context) {
                        Log.info('[TEST] STEP 2 SUCCESS');
                    },
                    onFail: function(context) {
                        Log.info('[TEST] STEP 2 FAILED');
                    }
                });
            } else {
                Log.info('[TEST] Step 2 Skipped (User is not Admin/Manager, or dynamicFlag mismatch)');
            }
        }
    });
};
