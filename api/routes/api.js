const express = require('express');

const routeModules = [
    require('./auth'),
    require('./profiles'),
    require('./teams'),
    require('./matches'),
    require('./players'),
    require('./join-requests'),
    require('./invitations'),
    require('./messages'),
    require('./notifications'),
    require('./admin'),
    require('./ai'),
    require('./payment')
];

module.exports = function registerRoutes(dependencies) {
    const router = express.Router();

    for (const registerRoute of routeModules) {
        registerRoute({ ...dependencies, app: router });
    }

    return router;
};
