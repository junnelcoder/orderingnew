const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');

router.get('/getUsers', async (req, res) => {
    try {
        const pool = await sql.connect(config);
        const result = await pool.request().query(`
            SELECT [user_id],[user_password] FROM [restopos45].[dbo].[user_access]
        `);
        const users = result.recordset.map(record => ({
            username: record.user_id,
            password: record.user_password
        }));
        res.json(users);
        
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

router.get('/ipConn', async (req,res) => {
    res.send('Hello from server!');
});
module.exports = router;
