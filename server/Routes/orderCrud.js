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

    // Add ORDER BY clause to sort items alphabetically by itemname
    query += ' ORDER BY itemname';

    const pool = await sql.connect(config);
    const result = await pool.request()
      .input('category', sql.VarChar, category)
      .query(query);

    // Filter out items with undesired categories
    const filteredItems = result.recordset.filter(item => {
      const itemCategory = item.category ? item.category.trim().toLowerCase() : '';
      return itemCategory !== '' && !['notes', 'notes', 'notes'].includes(itemCategory);
    });

    // Send the list of filtered and sorted items as a JSON response
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
    const noteItems = result.recordset; // Return the entire recordset
    res.json(noteItems);
  } catch (err) {
    console.error('Error executing SQL query:', err);
    res.status(500).json({ error: 'Failed to fetch note items' });
  }
});


// Endpoint to handle adding items to the cart
router.post('/add-to-cart', async (req, res) => {
  try {
    const { cartItems, selectedTablesString, switchValue } = req.body;


    let subtotalAmount = 0;
    let totalAmount = 0;
    let paid = 0;
    let machineid = 0;

    const pool = await sql.connect(config);
    const updateResult = await pool.request().query(`
      DECLARE @last_or VARCHAR(20);
      SELECT @last_or = last_or FROM [dbo].[business_date_res];

      DECLARE @new_or VARCHAR(20);
      SET @new_or = RIGHT('00000' + CAST(CAST(RIGHT(@last_or, 5) AS INT) + 1 AS VARCHAR), 5);

      UPDATE [dbo].[business_date_res] SET last_or = @new_or;

      SELECT @new_or AS new_or;
    `);

    const newSoNumber = updateResult.recordset[0].new_or;
    // Parse each item and insert into the database
    for (const item of cartItems) {
      const { pa_id, machine_id, trans_date, itemcode, itemname, category, qty, unitprice, markup, sellingprice, subtotal, total, department, uom, vatable, tran_time, division, section, brand, close_status } = JSON.parse(item);

      // Calculate subtotal and total amounts
      subtotalAmount += parseFloat(subtotal);
      totalAmount += parseFloat(total);
      paid = pa_id;
      machineid = machine_id;
      const newSoNumber = updateResult.recordset[0].new_or;
      console.log(newSoNumber);
      // Generate current date for trans_date
      const currentDate = new Date().toISOString().split('T')[0];

      // Generate current time for tran_time
      const currentTime = new Date().toLocaleTimeString('en-US', { hour12: false });

      // Format time to HH:mm:ss format
      const formattedTime = currentTime.split(' ')[0];

      // Combine date and time into a single datetime string
      const transDateTime = currentDate + ' ' + formattedTime;

      // Validate close_status
      const closeStatusInt = parseInt(close_status);

      const pool = await sql.connect(config);

      const request = pool.request()
        .input('pa_id', sql.Char, pa_id)
        .input('so_number', sql.VarChar, newSoNumber)
        .input('machine_id', sql.VarChar, machine_id)
        .input('trans_date', sql.DateTime, new Date(trans_date)) // Correctly pass trans_date
        .input('itemcode', sql.VarChar, itemcode)
        .input('itemname', sql.Char, itemname)
        .input('category', sql.VarChar, category)
        .input('qty', sql.Decimal(18, 2), qty)
        .input('unitprice', sql.Decimal(18, 2), parseFloat(unitprice)) // Parse unitprice to float
        .input('markup', sql.Decimal(18, 2), markup)
        .input('sellingprice', sql.Decimal(18, 2), sellingprice)
        .input('subtotal', sql.Decimal(18, 2), subtotal)
        .input('total', sql.Decimal(18, 2), total)
        .input('department', sql.VarChar, department)
        .input('uom', sql.Char, uom)
        .input('vatable', sql.TinyInt, vatable)
        .input('tran_time', sql.DateTime, new Date(transDateTime)) // Pass datetime object
        .input('division', sql.VarChar, division)
        .input('section', sql.VarChar, section)
        .input('brand', sql.VarChar, brand)
        .input('close_status', sql.TinyInt, closeStatusInt)
        .input('table_no', sql.VarChar, selectedTablesString)
        .input('order_service', sql.VarChar, switchValue);

      await request.query(`
        INSERT INTO [dbo].[so_detail] (pa_id, so_number, machine_id, trans_date, itemcode, itemname, category, qty, unitprice, markup, sellingprice, subtotal, total, department, uom, vatable, tran_time, division, section, brand, close_status,table_no, order_service)
        VALUES (@pa_id, @so_number, @machine_id, @trans_date, @itemcode, @itemname, @category, @qty, @unitprice, @markup, @sellingprice, @subtotal, @total, @department, @uom, @vatable, @tran_time, @division, @section, @brand, @close_status,@table_no, @order_service) 
      `);
    }

    // Insert into so_header table
    // const pool = await sql.connect(config);
    const requestHeader = pool.request()
      .input('so_number', sql.VarChar, newSoNumber) // Assuming so_number is fixed for all items
      .input('machine_id', sql.VarChar, machineid) // Assuming machine_id is same for all items
      .input('trans_date', sql.DateTime, new Date().toISOString().split('T')[0]) // Correctly pass trans_date
      .input('pa_id', sql.Char, paid) // Assuming pa_id is same for all items
      .input('subtotal_amount', sql.Decimal(18, 2), subtotalAmount)
      .input('total_amount', sql.Decimal(18, 2), totalAmount)
      .input('tran_time', sql.DateTime, new Date()) // Pass current datetime object
      .input('close_status', sql.TinyInt, 1)
      .input('table_no', sql.VarChar, selectedTablesString)
      .input('order_service', sql.VarChar, switchValue)
      .query(`
    INSERT INTO [dbo].[so_header] (so_number, machine_id, trans_date, pa_id, subtotal_amount, total_amount, tran_time, close_status, table_no, order_service) 
    VALUES (@so_number, @machine_id, @trans_date, @pa_id, @subtotal_amount, @total_amount, @tran_time, @close_status, @table_no, @order_service) 
  `);

    // Set close_status to 1 for all records in so_detail
    await pool.request().query(`
      UPDATE [dbo].[so_detail] 
      SET close_status = 1
    `);

    // Send a response indicating success
    res.status(200).json({ message: 'Items added to cart successfully' });
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

router.get('/tableno', async (req, res) => {
  try {
    await sql.connect(config);
    const query1 = `SELECT trans_no, table_no, occupied FROM tableno WHERE occupied = 0 ORDER BY trans_no ASC`;
    const result1 = await sql.query(query1);
    const query2 = `SELECT trans_no, table_no, occupied FROM tableno WHERE occupied = 1 ORDER BY trans_no`;
    const result2 = await sql.query(query2);
    res.json({ occupied_0: result1.recordset, occupied_1: result2.recordset });
  } catch (err) {
    console.error(err);
    res.status(500).send('Internal Server Error');
  }
});

router.post('/occupy', async (req, res) => {
  try {
    const selectedIndex = req.body;
    console.log(selectedIndex);
    if (isNaN(selectedIndex)) {
      return res.status(400).json({ error: 'Invalid input. Please provide a valid integer.' });
    }

    const pool = await sql.connect(config);
    const updateQuery = `
        UPDATE [dbo].[tableno]
        SET [occupied] = 1
        WHERE [trans_no] = @selectedIndex
      `;

    const request = pool.request();
    request.input('selectedIndex', sql.Int, selectedIndex);

    const result = await request.query(updateQuery);
    res.status(200).json({ message: `Table ${selectedIndex} occupied successfully.` });
  } catch (err) {
    console.error('Error updating occupied status:', err);
    res.status(500).json({ error: 'Failed to update occupied status.', message: err.message, stack: err.stack });
  }
});

router.get('/todaysTransactions', async (req, res) => {
  try {
    const pool = await sql.connect(config);
    const result = await pool.request().query(`
            SELECT
                [so_number],
                [machine_id],
                [trans_date],
                [pa_id],
                [subtotal_amount],
                [total_amount],
                FORMAT([tran_time], 'HH:mm') AS tran_time,
                [table_no],
                [order_service],
                [close_status],
                [posted]
            FROM [restopos45].[dbo].[so_header]
            WHERE CONVERT(date, tran_time) = CONVERT(date, GETDATE())
            ORDER BY so_number DESC;      
        `);
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).send('Internal Server Error');
  }
});

router.get('/soDetailData', async (req, res) => {
  try {
    const pool = await sql.connect(config);
    const result = await pool.request().query('SELECT * FROM dbo.so_detail');
    res.status(200).json(result.recordset);
  } catch (error) {
    console.error('Error fetching data:', error);
    res.status(500).send(`Error fetching data: ${error.message}`);
  }
});

router.post('/delete-items', async (req, res) => {
  try {
    const { trans_no, count } = req.body;
    console.log('Received data:');
    console.log('Transaction Number:', trans_no);
    console.log('Count:', count);
    const pool = await sql.connect(config);
    if (count === 1) {//kapag isa nalang yung item, idedelete na sa parehong table
      const fetchRequest = pool.request().input('trans_no', sql.BigInt, trans_no);
      const fetchResult = await fetchRequest.query(`
        SELECT [so_number] FROM [dbo].[so_detail]
        WHERE [trans_no] = @trans_no 
      `);//kinuha ko muna yung trans_no sa so_details table kase walang trans_no sa so_header kaya yung so_number gagamitin ko
      if (fetchResult.recordset.length === 0) {
        res.status(404).json({ message: 'Transaction not found' });
      } else {
        const so_number = fetchResult.recordset[0].so_number;
        const deleteDetailRequest = pool.request().input('so_number', sql.VarChar, so_number);
        await deleteDetailRequest.query(`
          DELETE FROM [dbo].[so_detail]
          WHERE [so_number] = @so_number
        `);// ginamit ko yung so_number para idelete yung column na target ko na madelete
        const deleteHeaderRequest = pool.request().input('so_number', sql.VarChar, so_number);
        await deleteHeaderRequest.query(`
          DELETE FROM [dbo].[so_header]
          WHERE [so_number] = @so_number
        `);// ginamit kona din dito yung so_number pala idelete yung column na target ko na madelete
        console.log(`Deleted all rows with so_number: ${so_number}`);
        res.status(200).json({ message: 'Items deleted successfully' });
      }
    }else if(count === 888){
      const fetchRequest = pool.request().input('trans_no', sql.BigInt, trans_no);
      const fetchResult = await fetchRequest.query(`
        SELECT [so_number] FROM [dbo].[so_detail]
        WHERE [trans_no] = @trans_no 
      `);//kinuha ko muna yung trans_no sa so_details table kase walang trans_no sa so_header kaya yung so_number gagamitin ko
      if (fetchResult.recordset.length === 0) {
        res.status(404).json({ message: 'Transaction not found' });
      } else {
        const deleteDetailRequest = pool.request().input('trans_no', sql.VarChar, trans_no);
        await deleteDetailRequest.query(`
          DELETE FROM [dbo].[so_detail]
          WHERE [trans_no] = @trans_no
        `);// ginamit ko yung so_number para idelete yung column na target ko na madelete
        const so_number = fetchResult.recordset[0].so_number;
        const deleteHeaderRequest = pool.request().input('so_number', sql.VarChar, so_number);
        await deleteHeaderRequest.query(`
          DELETE FROM [dbo].[so_header]
          WHERE [so_number] = @so_number
        `);// ginamit kona din dito yung so_number pala idelete yung column na target ko na madelete
        console.log(`Deleted all rows with so_number: ${so_number}`);
        res.status(200).json({ message: 'Items deleted successfully' });
    }
  }else {
      const fetchRequest = pool.request().input('trans_no', sql.BigInt, trans_no);
      const fetchResult = await fetchRequest.query(`
        SELECT [so_number],[sellingprice] FROM [dbo].[so_detail]
        WHERE [trans_no] = @trans_no
      `);//gagana lang to kapag mas mataas sa 1 yung laman ng endpoint ko
      if (fetchResult.recordset.length === 0) {
        res.status(404).json({ message: 'Transaction not found' });
      } else {
        const so_number = fetchResult.recordset[0].so_number;
        const sellingprice = fetchResult.recordset[0].sellingprice;
        const fetchRequest2 = pool.request().input('so_number', sql.VarChar, so_number);
        const fetchResult2 = await fetchRequest2.query(`
          SELECT [total_amount] FROM [dbo].[so_header]
          WHERE [so_number] = @so_number
        `);// tulad kanina, kinuha ko muna yung so_number sa so_detail na table, kinuha kona din yung sellingprice para maupdate ko yung total price mamaya
        if (fetchResult2.recordset.length === 0) {
          res.status(404).json({ message: 'Transaction not found' });
        } else {
          const total_amount = fetchResult2.recordset[0].total_amount - sellingprice;
          const updateRequest = pool.request()
            .input('total_amount', sql.BigInt, total_amount)
            .input('so_number', sql.VarChar, so_number);
          await updateRequest.query(`
            UPDATE [dbo].[so_header]
            SET [total_amount] = @total_amount
            WHERE [so_number] = @so_number
          `);// inupdate kona dito yung total_amount ng so_header gamit yung bagong total amount
          const deleteRequest = pool.request().input('trans_no', sql.VarChar, trans_no);
          await deleteRequest.query(`
            DELETE FROM [dbo].[so_detail]
            WHERE [trans_no] = @trans_no
          `);// idedelete kona dito yung target ko na item sa so_detail
          console.log(`Deleted all rows with so_number: ${so_number}`);
          res.status(200).json({ message: 'Items deleted successfully' });
        }
      }
    }
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});





module.exports = router;
