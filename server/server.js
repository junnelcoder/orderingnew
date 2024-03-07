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

// Parse JSON bodies
app.use(bodyParser.json());

// const testRoutes = require('./Routes/testing');
// app.use('/api', testRoutes); 
const item = require('./Routes/itemListingRoutes');
const auth = require('./Routes/authenticationRoute');
app.use('/api', item); 
app.use('/api', auth); 

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
    let query = 'SELECT * FROM [restopos45].[dbo].[items]';

    // If a specific category is selected, filter by that category
    if (category && category !== 'ALL') {
      category = decodeURIComponent(category); // Decode the category parameter
      query += ' WHERE category = @category';
    }

    const pool = await sql.connect(config);
    const result = await pool.request()
                               .input('category', sql.VarChar, category)
                               .query(query);
    
    // Send the list of items as a JSON response
    res.json(result.recordset);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});


// Endpoint to handle adding items to the cart
app.post('/add-to-cart', async (req, res) => {
  try {
    // Extract item details from the request body
    const { pa_id, machine_id, itemcode, itemname, category, qty, unitprice, markup, sellingprice, department, uom, vatable, tran_time, division, section, brand, close_status, picture_path,total,subtotal } = req.body;
    const trans_date = new Date().toISOString().split('T')[0]; // Extract date portion only
    
    // Calculate subtotal and total
    
    
    // Connect to the database
    const pool = await sql.connect(config);
    
    // Insert the item details into the cart_items table using parameterized query
    const request = pool.request()
        .input('pa_id', sql.VarChar, pa_id)
        .input('machine_id', sql.VarChar, machine_id)
        .input('trans_date', sql.Date, trans_date)
        .input('itemcode', sql.VarChar, itemcode)
        .input('itemname', sql.VarChar, itemname)
        .input('category', sql.VarChar, category)
        .input('qty', sql.VarChar, qty)
        .input('unitprice', sql.VarChar, unitprice)
        .input('markup', sql.VarChar, markup)
        .input('sellingprice', sql.VarChar, sellingprice)
        .input('department', sql.VarChar, department)
        .input('uom', sql.VarChar, uom)
        .input('vatable', sql.VarChar, vatable)
        .input('tran_time', sql.VarChar, tran_time)
        .input('division', sql.VarChar, division)
        .input('section', sql.VarChar, section)
        .input('brand', sql.VarChar, brand)
        .input('close_status', sql.TinyInt, close_status) // Use TinyInt for close_status
        .input('picture_path', sql.VarChar, picture_path)
        .input('subtotal', sql.VarChar, subtotal)
        .input('total', sql.VarChar, total);
      
    await request.query(`
      INSERT INTO [restopos45].[dbo].[cart_items] (pa_id, machine_id, trans_date, itemcode, itemname, category, qty, unitprice, markup, sellingprice, department, uom, vatable, tran_time, division, brand, section, close_status, picture_path, subtotal, total)
      VALUES (@pa_id, @machine_id, @trans_date, @itemcode, @itemname, @category, @qty, @unitprice, @markup, @sellingprice, @department, @uom, @vatable, @tran_time, @division, @brand, @section, @close_status, @picture_path, @subtotal, @total)
    `);
    
    // Send a response indicating success
    res.status(200).json({ message: 'Item added to cart successfully' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});




const config = {
    user: 'sa',
    password: 'zankojt@2024',
    server: 'DESKTOP-EIR2A8B\\SQLEXPRESS2014',
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

// // Start the server
// app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

sql.connect(config)
  .then(() => {
    console.log('Connected to SQL Server');
  })
  .catch((err) => {
    console.error('Error connecting to SQL Server:', err);
  });
