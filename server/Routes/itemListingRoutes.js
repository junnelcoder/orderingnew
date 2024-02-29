const express = require('express');
const router = express.Router();
const app = express();
const axios = require('axios');
const sql = require('mssql');
const config = require('./server.js');

router.get('/item', async (req, res) => {
    try {
        const pool = await sql.connect(config);
        const result = await pool.request().query(`
            SELECT TOP (1000) [trans_no], [itemcode], [itemname], [category], [sellingprice]
            FROM [restopos45].[dbo].[items]
        `);
        res.json(result.recordset);
        console.log(result.recordset);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;