const express = require('express');
const app = express();
const axios = require('axios');
const sql = require('mssql');
const bodyParser = require('body-parser'); // Import bodyParser
const PORT = 8080;
const http = require('http');
const ip = require('ip');

// Add CORS middleware
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*'); // Allow requests from any origin
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS'); // Allow specific HTTP methods
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization'); // Allow specific headers
  next();
});
app.use(bodyParser.json());

const item = require('./Routes/itemListingRoutes');
const auth = require('./Routes/authenticationRoute');
const crud = require('./Routes/orderCrud');
app.use('/api', item); 
app.use('/api', auth); 
app.use('/api', crud); 

const config = {
    user: 'sa',
    password: 'zankojt@2024',
    server: 'DESKTOP-Q3V7PHJ\\SQLEXPRESS2014',
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
  console.log(`Your server IP is: ${ipAddress}`);
});

sql.connect(config)
  .then(() => {
    console.log('Connected to SQL Server');
  })
  .catch((err) => {
    console.error('Error connecting to SQL Server:', err);
  });
