require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { sql, connectDatabase } = require('./config/database');
const registerRoutes = require('./routes/api');

const app = express();
const port = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';

app.use(cors());
app.use(express.json());

const apiRouter = registerRoutes({ app, sql, bcrypt, jwt, JWT_SECRET });
app.use('/api', apiRouter);

connectDatabase();

app.listen(port, () => {
    console.log(`Backend running at http://localhost:${port}`);
});

module.exports = app;
