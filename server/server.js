const express = require('express');
const app = express();
const axios = require('axios');
const sql = require('mssql');
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

// const testRoutes = require('./Routes/testing');
const item = require('./Routes/itemListingRoutes');
// app.use('/api', testRoutes); 
app.use('/api', item); 
app.get('/categories', async (req, res) => {
  try {
    const pool = await sql.connect(config);
    const result = await pool.request().query(`
      SELECT DISTINCT [category] FROM [restopos45].[dbo].[items]
    `);
    const categories = result.recordset.map(record => record.category);
    res.json(categories);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

app.get('/items', async (req, res) => {
  try {
    let category = req.query.category;

    let query = 'SELECT itemName, itemCode, sellingPrice FROM [restopos45].[dbo].[items]';

    // If a specific category is selected, filter by that category
    if (category && category !== 'ALL') {
      category = decodeURIComponent(category); // Decode the category parameter
      query += ` WHERE category = '${category}'`;
    }

    const pool = await sql.connect(config);
    const result = await pool.request().query(query);
    
    // Send the list of items as a JSON response
    res.json(result.recordset);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});






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
