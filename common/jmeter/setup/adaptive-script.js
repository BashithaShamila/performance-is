var rolesToStepUp = ['admin', 'manager'];

var onLoginRequest = function(context) {
    executeStep(1, {
        onSuccess: function(context) {
            var user = context.currentKnownSubject;
            if (user && hasAnyOfTheRolesV2(context, rolesToStepUp)) {
                executeStep(2);
            }
        }
    });
};
