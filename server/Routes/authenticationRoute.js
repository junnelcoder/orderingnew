const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');
const bcrypt = require('bcrypt');

router.get('/getUsers', async (req, res) => {
  try {
    const pool = await sql.connect(config);
    const result = await pool.request().query(`
      SELECT [user_id] FROM [restopos45].[dbo].[user_access]
    `);
    const users = result.recordset.map(record => ({
      username: record.user_id
    }));
    
    // console.log(result);
    res.json(users);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});


router.get('/getTerminalId', (req, res) => {
  
  // SQL query to fetch terminal_id based on user_id
  const query = (`select machine_id as terminal_number from machine_setup where mac_address = convert(varchar(255), (select serverproperty('MachineName')))`);
  // machine_id = (select machine_id from machine_setup where mac_address = convert(varchar(255), (select serverproperty('MachineName'))))
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

router.post('/auth/login', async (req, res) => {
  let { username, password } = req.body;

  let x = 0;
  let letter = "";

  if (password.length !== 0) {
    while (x < password.length) {
      var n = password.charCodeAt(x) + (x + 1);
      letter = letter + String.fromCharCode(n);
      x++;
    }
  }

  password = letter;

  try {
    const pool = await sql.connect(config);
    const result = await pool
      .request()
      .input('username', sql.VarChar, username)
      .input('password', sql.VarChar, password)
      .query('SELECT rtrim(ltrim(user_id)) as user_id FROM user_access WHERE user_id = @username AND user_password = @password');

    if (result.recordset.length === 0) {
      return res.sendStatus(401);
    }

    req.session.user = result.recordset[0].user_id;
    res.sendStatus(200);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

router.post('/updatePrinterIP', async (req, res) => {
  const { ip_address_printer } = req.body;

  if (!ip_address_printer) {
    return res.status(400).send('Printer IP cannot be empty');
  }

  try {
    const pool = await sql.connect(config);
    await pool.request()
      .input('ip_address_printer', sql.VarChar, ip_address_printer)
      .query("UPDATE sys_setup SET ip_address_printer = @ip_address_printer WHERE trans_no = 1");

    res.status(200).send('Printer IP updated successfully');
  } catch (err) {
    console.error('SQL error', err);
    res.status(500).send('Server error');
  }
});

router.get('/ipConn', async (req,res) => {
    res.send('Hello from server!');
});
module.exports = router;
