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

router.post('/auth/login', async (req, res) => {
  const { username, password } = req.body;
  console.log(req.body);
  try {
      const pool = await sql.connect(config);
      
      const result = await pool
          .request()
          .input('username', sql.VarChar, username)
          .query(`SELECT isNull(user_password, 'null') AS user_password FROM [restopos45].[dbo].[user_access] WHERE [user_id] = @username`);
      console.log(result.recordset);

      if (result.recordset.length === 0) {
          res.status(402).json({ message: 'User not found' });
          return;
      }

      const hashedPassword = result.recordset[0].user_password;
      console.log(hashedPassword, password);

      // Check if the password is empty, null, or not provided
      if (!password || password.trim() === '') {
          // If password is empty, null, or not provided, compare directly without encryption
          if (!hashedPassword || hashedPassword === 'null') {
              // Password matches if both are empty or null
              res.status(200).json({ message: 'Login successful' });
          } else {
              // Password does not match if database password is not empty or null
              res.status(401).json({ message: 'Invalid password' });
          }
      } else {
          // Compare the provided password with the hashed password from the database using bcrypt.compare
          const isMatch = await bcrypt.compare(password, hashedPassword);
          console.log(isMatch);

          if (isMatch) {
            res.status(200).json({ message: 'Login successful' });
              
          } else {
              // Incorrect password
              res.status(401).json({ message: 'Invalid password' });
          }
      }
  } catch (err) {
      console.error(err.message);
      res.status(500).send('Server Error');
  }
});


router.get('/ipConn', async (req,res) => {
    res.send('Hello from server!');
});
module.exports = router;
