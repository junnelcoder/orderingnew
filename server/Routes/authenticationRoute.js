const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');

router.get('/getUsers', async (req, res) => {
    try {
        const pool = await sql.connect(config);
        const result = await pool.request().query(`
            SELECT [cashier_name],[password] FROM [restopos45].[dbo].[user]
        `);
        const users = result.recordset.map(record => ({
            username: record.cashier_name,
            password: record.password
        }));
        res.json(users);
        
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
