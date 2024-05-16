const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');

router.get('/getUsers', async (req, res) => {
    try {
      const pool = await sql.connect(config);
      const result = await pool.request().query(`
        SELECT [user_id] FROM [restopos45].[dbo].[user_access]
      `);
      const users = result.recordset.map(record => ({
        username: record.user_id
      }));
      
      console.log(result);
      res.json(users);
    } catch (err) {
      console.error(err.message);
      res.status(500).send('Server Error');
    }
  });

router.post('/login', async (req, res) => {
    const { username, password } = req.body;
  
    try {
      const pool = await sql.connect(config);
      const result = await pool
        .request()
        .input('username', sql.VarChar, username)
        .query('SELECT [user_password] FROM [restopos45].[dbo].[user_access] WHERE [user_id] = @username');
  
      if (result.recordset.length === 0) {
        res.status(401).json({ message: 'User not found' });
        return;
      }
  
      const hashedPassword = result.recordset[0].user_password;
  
  
      if (providedPassword === hashedPassword) {
        // Authentication successful
        res.status(200).json({ message: 'Login successful' });
      } else {
        // Incorrect password
        res.status(401).json({ message: 'Invalid password' });
      }
    } catch (err) {
      console.error(err.message);
      res.status(500).send('Server Error');
    }
  });
  

router.post('/device', (req, res) => {
    const deviceInfo = req.body; // Assuming device information is sent in the request body
    console.log('Received device information:', deviceInfo);

    // Extract the device ID from the request body
    const deviceId = deviceInfo.deviceId;
    console.log('Received device ID:', deviceId);

    // Predefined authorized device ID
    const authorizedDeviceId = '81c318cd9579ceb5';

    // Compare the received device ID with the authorized device ID
    if (deviceId === authorizedDeviceId) {
        // Device is authorized
        console.log('Device is authorized');
        res.sendStatus(200); // Send a success response
    } else {
        // Device is not authorized
        console.log('Device is not authorized');
        res.status(401).send('Unauthorized'); // Send an error response
    }
});


router.get('/ipConn', async (req,res) => {
    res.send('Hello from server!');
});
module.exports = router;
