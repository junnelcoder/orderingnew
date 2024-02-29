const express = require('express');
const app = express();
const axios = require('axios');
const sql = require('mssql');
const PORT = 8080;
const http = require('http');
const ip = require('ip');

// const testRoutes = require('./Routes/testing');
const item = require('./Routes/itemListingRoutes');
// app.use('/api', testRoutes); 
app.use('/api', item); 

const config = {
    user: 'sa',
    password: 'zankojt@2024',
    server: 'DESKTOP-6S6CLHO\\SQLEXPRESS2014',
    database: 'restopos45',
    options: {
        encrypt: false, 
        enableArithAbort: true 
    }
};

const server = http.createServer(app);

server.listen(PORT, () => {
  const ipAddress = ip.address(); 
  console.log(`Server is running at http://${ipAddress}:${PORT}`);
});

// // Start the server
// app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

sql.connect(config)
  .then(() => {
    console.log('Connected to SQL Server');
  })
  .catch((err) => {
    console.error('Error connecting to SQL Server:', err);
  });
