const express = require('express');
const app = express();
const axios = require('axios');
const sql = require('mssql');
const bodyParser = require('body-parser');
const PORT = 8080;
const http = require('http');
const ip = require('ip');
const path = require('path');

// Add CORS middleware
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  next();
});
app.use(bodyParser.json());

// Serve static files (images) from the 'images' directory
app.use('/images', express.static(path.join(__dirname, 'images')));

// Your other routes
const item = require('./Routes/itemListingRoutes');
const auth = require('./Routes/authenticationRoute');
const crud = require('./Routes/orderCrud');
app.use('/api', item);
app.use('/api', auth);
app.use('/api', crud);

// Endpoint to serve images based on itemcode
app.get('/api/image/:itemcode', (req, res) => {
  const itemcode = req.params.itemcode;
  // const currentDirectory = process.cwd();
  const imagePath = path.join(__dirname, 'images', `${itemcode}.png`);
  res.sendFile(imagePath);
});

const config = {
  user: 'sa',
  password: 'zankojt@2024',
  server: 'DESKTOP-6s6clho\\SQLEXPRESS2014',
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
