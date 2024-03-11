const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');

router.get('/categories', async (req, res) => {
    try {
      const pool = await sql.connect(config);
      const result = await pool.request().query(`
        SELECT DISTINCT [category] FROM [restopos45].[dbo].[items]
      `);
      const categories = result.recordset.map(record => record.category);
  
      // Filter out categories containing 'notes', 'NOTES', or 'Notes'
      const filteredCategories = categories.filter(category => !/notes/i.test(category));
  
      res.json(filteredCategories);
    } catch (err) {
      console.error(err.message);
      res.status(500).send('Server Error');
    }
  });


router.get('/items', async (req, res) => {
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
      
      // Filter out items with undesired categories
      const filteredItems = result.recordset.filter(item => {
        const itemCategory = item.category ? item.category.trim().toLowerCase() : '';
        return itemCategory !== '' && !['notes', 'notes', 'notes'].includes(itemCategory);
      });
      
      // Send the list of filtered items as a JSON response
      res.json(filteredItems);
    } catch (err) {
      console.error(err.message);
      res.status(500).send('Server Error');
    }
  });

  
router.get('/allItems', async (req, res) => {
  try {
    const pool = await sql.connect(config);
    const result = await pool.request().query(`
    SELECT * FROM [restopos45].[dbo].[items]
    `);
    res.json(result);
  } catch (err) {
    console.error('Error executing SQL query:', err);
    res.status(500).json({ error: 'Failed to fetch note items' });
  }
});

  // Endpoint para sa pag-add sa cart ng mga notes
router.post('/add-notes-to-cart', async (req, res) => {
    try {
      // Extract item details from the request body
      const { pa_id, machine_id, itemname, category, qty, unitprice, markup, sellingprice, department, uom, vatable, tran_time, division, section, brand, close_status, picture_path, total, subtotal } = req.body;
      const trans_date = new Date().toISOString().split('T')[0]; // Extract date portion only
      
      // Connect to the database
      const pool = await sql.connect(config);
      
      // Insert the item details into the cart_items table using parameterized query
      const request = pool.request()
          .input('pa_id', sql.VarChar, pa_id)
          .input('machine_id', sql.VarChar, machine_id)
          .input('trans_date', sql.Date, trans_date)
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
          .input('total', sql.VarChar, total); // Set notes to null
      
      await request.query(`
        INSERT INTO [restopos45].[dbo].[cart_items] (pa_id, machine_id, trans_date, itemname, category, qty, unitprice, markup, sellingprice, department, uom, vatable, tran_time, division, brand, section, close_status, picture_path, subtotal, total)
        VALUES (@pa_id, @machine_id, @trans_date, @itemname, @category, @qty, @unitprice, @markup, @sellingprice, @department, @uom, @vatable, @tran_time, @division, @brand, @section, @close_status, @picture_path, @subtotal, @total)
      `);
      
      // Send a response indicating success
      res.status(200).json({ message: 'Notes added to cart successfully' });
    } catch (err) {
      console.error(err.message);
      res.status(500).send('Server Error');
    }
  });

  
router.get('/get-notes', async (req, res) => {
    try {
      const pool = await sql.connect(config);
      const result = await pool.request().query(`
        SELECT * FROM [restopos45].[dbo].[items] WHERE category LIKE '%NOTES%' AND itemname IS NOT NULL
      `);
      const noteItems = result.recordset.map(record => record.itemname);
      res.json(noteItems);
    } catch (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).json({ error: 'Failed to fetch note items' });
    }
  });

// Endpoint to handle adding items to the cart
router.post('/add-to-cart', async (req, res) => {
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

  router.get('/get-open-cart-items-count', async (req, res) => {
    try {
      // Connect to the database
      const pool = await sql.connect(config);
      
      // Execute a query to get the count of open cart items excluding notes
      const result = await pool.request().query(`
        SELECT COUNT(*) AS openCartItemCount 
        FROM [restopos45].[dbo].[cart_items] 
        WHERE close_status = 0
        AND category NOT LIKE '%NOTES%'
      `);
      
      // Extract the count from the query result
      const openCartItemCount = result.recordset[0].openCartItemCount;
      
      // Send the count as a response
      res.status(200).json({ count: openCartItemCount });
    } catch (err) {
      console.error('Error:', err.message);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
module.exports = router;
