const registerAuthRoutes = require('./auth');
const registerProfileRoutes = require('./profiles');
const registerPlayerRoutes = require('./players');
const registerTeamRoutes = require('./teams');
const registerMatchRoutes = require('./matches');
const registerJoinRequestRoutes = require('./join-requests');
const registerInvitationRoutes = require('./invitations');
const registerMessageRoutes = require('./messages');
const registerNotificationRoutes = require('./notifications');

module.exports = function registerApiRoutes(context) {
    registerAuthRoutes(context);
    registerProfileRoutes(context);
    registerPlayerRoutes(context);
    registerTeamRoutes(context);
    registerMatchRoutes(context);
    registerJoinRequestRoutes(context);
    registerInvitationRoutes(context);
    registerMessageRoutes(context);
    registerNotificationRoutes(context);
};
