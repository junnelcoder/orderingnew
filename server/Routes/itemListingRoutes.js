const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');

router.get('/categories', async (req, res) => {
    try {
        const pool = await sql.connect(config);
        const result = await pool.request().query(`
        select distinct isnull(rtrim(ltrim(category)), 'null') as category from items where category is not null and category != 'NOTES' order by category asc
        `);
        const categories = result.recordset.map(record => record.category);
        res.json(categories);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});


module.exports = router;
