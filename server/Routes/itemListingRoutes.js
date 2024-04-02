const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');

router.get('/categories', async (req, res) => {
    try {
        const pool = await sql.connect(config);
        const result = await pool.request().query(`
            SELECT DISTINCT [category] FROM [restopos45].[dbo].[items]
            WHERE [category] NOT IN ('notes', 'NOTES', 'Notes')
        `);
        const categories = result.recordset.map(record => record.category);
        res.json(categories);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

router.get('/getTerminalId', (req, res) => {
  
    // SQL query to fetch terminal_id based on user_id
    const query = `SELECT terminal_number FROM sys_setup`;
  
    // Execute the query
    sql.query(query)
      .then(result => {
        if (result.recordset.length > 0) {
          const terminalId = result.recordset[0].terminal_number;
          res.json({ terminalId });
        } else {
          res.status(404).json({ message: 'Terminal ID not found for the specified user ID' });
        }
      })
      .catch(error => {
        console.error('Error executing SQL query:', error);
        res.status(500).json({ message: 'Internal server error' });
      });
  });

module.exports = router;
