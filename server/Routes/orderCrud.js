const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');
const net = require('net');
const { ThermalPrinter, PrinterTypes, CharacterSet, BreakLine } = require('node-thermal-printer');
const { printOrderSlip } = require('../Routes/printer.js');
const config2 = require('../config.json');


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



// Create a new network connection to the printer

// const printOrderSlip = async (printer, newSoNumber, selectedTablesString, paid) => {
//   try {
//     if (!printer) {
//       console.log('Printer is not available. Order slip could not be printed.');
//       return { error: 'Printer is not available. Order slip could not be printed.' };
//     }
//     printer.alignCenter();
//     printer.println('SPARKY ORDERING');
//     printer.println('ORDER SLIP');
//     printer.println(`Date: ${new Date().toLocaleDateString('en-US')}, ${new Date().toLocaleTimeString('en-US', { hour12: true })}`);
//     printer.println(`SO NUMBER: ${newSoNumber}`);
//     printer.println('------------------------------------');
//     printer.println(`- - - ORDER FOR: ${selectedTablesString} - - -`);
//     printer.println('------------------------------------');
//     printer.println(`Order Taker: ${paid}`);
//     printer.cut({ verticalTabAmount: 1 });
//     await printer.execute();
//     printer.clear();
//     console.log('Order slip printed successfully');
//     return { success: 'Order slip printed successfully' };
//   } catch (error) {
//     console.error('Error printing order slip, No printer detected/connected');
//     return { error: 'Error printing order slip' };
//   }
// };


router.post('/saveOrder', async (req, res) => {
  const { content, summary, add_order } = req.body;
  let so_number = "";

  try {
    const pool = await sql.connect(config);

    if (add_order === 0) {
      await pool.request().execute('sp_so_number_handler');

      const generate_so_number = await pool.request()
        .query("SELECT last_or FROM business_date_res");
      so_number = generate_so_number.recordset[0].last_or;
    } else if (add_order === 1) {
      const getExistingSo = await pool.request()
        .input('table_no', sql.VarChar, summary.table_no)
        .query("SELECT MAX(so_number) AS so_number FROM so_header WHERE table_no = @table_no");
      so_number = getExistingSo.recordset[0].so_number;
    }
    console.log(`haha: ${so_number}`);

    for (let item of content) {
      await pool.request()
        .input('pa_id', sql.VarChar, item.pa_id)
        .input('machine_id', sql.VarChar, item.machine_id)
        .input('itemcode', sql.VarChar, item.itemcode)
        .input('itemname', sql.VarChar, item.itemname)
        .input('category', sql.VarChar, item.category)
        .input('qty', sql.Int, item.qty)
        .input('unitprice', sql.Decimal, item.unitprice)
        .input('markup', sql.Decimal, item.markup)
        .input('sellingprice', sql.Decimal, item.sellingprice)
        .input('subtotal', sql.Decimal, item.subtotal)
        .input('total', sql.Decimal, item.total)
        .input('department', sql.VarChar, item.department)
        .input('uom', sql.VarChar, item.uom)
        .input('vatable', sql.Bit, item.vatable)
        .input('division', sql.VarChar, item.division)
        .input('section', sql.VarChar, item.section)
        .input('brand', sql.VarChar, item.brand)
        .input('table_no', sql.VarChar, summary.table_no)
        .input('order_service', sql.VarChar, summary.order_service)
        .query(`EXEC sp_add_to_so_detail @pa_id,
                                      '${so_number}',
                                      @machine_id,
                                      @itemcode,
                                      @itemname,
                                      @category,
                                      @qty,
                                      @unitprice,
                                      @markup,
                                      @sellingprice,
                                      @subtotal,
                                      @total,
                                      @department,
                                      @uom,
                                      @vatable,
                                      @division,
                                      @section,
                                      @brand,
                                      @table_no,
                                      @order_service,
                                      ${add_order}`);
    }
    console.log(summary);

    await pool.request()
      .input('so_number', sql.VarChar, so_number)
      .input('machine_id', sql.VarChar, summary.machine_id)
      .input('pa_id', sql.VarChar, summary.pa_id)
      .input('total', sql.Decimal, summary.total)
      .input('table_no', sql.VarChar, summary.table_no)
      .input('order_service', sql.VarChar, summary.order_service)
      .query(`EXEC sp_add_to_so_header @so_number,
                                        @machine_id,
                                        @pa_id,
                                        @total,
                                        @table_no,
                                        @order_service`);

    await pool.request()
      .input('table_no', sql.VarChar, summary.table_no)
      .query("UPDATE tableno SET occupied = 0, status = 'O' WHERE table_no = @table_no");

    await pool.request().query("UPDATE notification SET notif = 1");

    const summary2 = {
      user: req.session.user,
      soNo: so_number,
      tableNo: summary.table_no,
      orderType: summary.order_service,
    };

    // Call the printOrderSlip function with the summary and content
    await printOrderSlip(summary2, content);

    res.sendStatus(200);
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
    const query = `
    SELECT trans_no, 
    ISNULL(RTRIM(LTRIM(table_no)), 'NULL') as table_no, 
    
	CASE
		WHEN billout = 0 and (occupied = 1 and status = 'C' or (occupied = 0 and status = 'O') or (occupied = 1 and status = 'O')) THEN 'inuse'
		WHEN billout = 1 and status = 'O' THEN 'billout'
		ELSE 'vacant'
	END as table_mark
FROM tableno TN
ORDER BY trans_no ASC
    `;
    const result = await sql.query(query);
    res.json({ result: result.recordset});
  } catch (err) {
    console.error(err);
    res.status(500).send('Internal Server Error');
  }
});

router.post('/occupy', async (req, res) => {
  try {
    const { previousIndex, selectedIndex, action, changeSelected } = req.body;
    const change = req.body.changeSelected;
    console.log("change ", change);
    console.log("previous ", previousIndex);
    console.log("selected ", selectedIndex);
    if (isNaN(selectedIndex)) {
      return res.status(400).json({ error: 'Invalid input. Please provide a valid integer.' });
    }

    const pool = await sql.connect(config);
    if (change != 1) {
      const updateQuery = `
    UPDATE [dbo].[tableno]
    SET [occupied] = @action
    WHERE [trans_no] = @selectedIndex
  `;
      const request = pool.request();
      request.input('selectedIndex', sql.Int, selectedIndex);
      request.input('action', sql.Int, action);

      const result = await request.query(updateQuery);
      res.status(200).json({ message: `Table ${selectedIndex} occupied successfully.` });
    } else if (changeSelected == 1) {
      const changeQuery = `
      UPDATE [dbo].[tableno]
SET [occupied] = 
  CASE
    WHEN [trans_no] = @previousIndex THEN 0
    WHEN [trans_no] = @selectedIndex THEN 1
    ELSE [occupied]
  END
WHERE [trans_no] IN (@previousIndex, @selectedIndex);

    `;

      const request = pool.request();
      request.input('selectedIndex', sql.Int, selectedIndex);
      request.input('previousIndex', sql.Int, previousIndex);

      const result = await request.query(changeQuery);
      res.status(200).json({ message: `Table ${selectedIndex} occupied successfully.` });
    }

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
    } else if (count === 888) {
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
    } else {
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

router.get('/get-last_inv', async (req, res) => {
  try {
    const pool = await sql.connect(config);
    const result = await pool
      .request()
      .query(`
       exec sp_unique_num
      `);
    const lastInvDigits = result.recordset;
    res.json(lastInvDigits);
  } catch (err) {
    console.error('Error executing SQL query:', err);
    res.status(500).json({ error: 'Failed to fetch last_inv digits' });
  }
});




module.exports = router;
