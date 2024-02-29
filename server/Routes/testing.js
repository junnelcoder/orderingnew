const express = require('express');
const router = express.Router();
const app = express();
const axios = require('axios');
const sql = require('mssql');


router.get('/test', (req, res) => {
    res.send('Testing route is working!');
    console.log("running");
});

module.exports = router;