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
