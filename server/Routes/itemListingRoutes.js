const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');

router.get('/subitems', async (req, res) => {
  try {
    const pool = await sql.connect(config);
    const itemcode = req.query.itemcode;

    // Query items_costing table to get sub_itemcode associated with the provided itemcode
    const itemCostingQuery = `
      SELECT sub_itemcode
      FROM items_costing
      WHERE itemcode = @itemcode
    `;
    const itemCostingResult = await pool.request()
      .input('itemcode', sql.Char(16), itemcode)
      .query(itemCostingQuery);

    // Extract sub_itemcode from the result
    const subItemcode = itemCostingResult.recordset[0].sub_itemcode;

    // Query items table to get details of the sub-items
    const subItemsQuery = `
      SELECT *
      FROM items
      WHERE itemcode = @subItemcode
    `;
    const subItemsResult = await pool.request()
      .input('subItemcode', sql.Char(16), subItemcode)
      .query(subItemsQuery);

    // Send the list of sub-items as a JSON response
    res.json(subItemsResult.recordset);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});



router.get('/categories', async (req, res) => {
    try {
        const pool = await sql.connect(config);
        const result = await pool.request().query(`
        select distinct isnull(rtrim(ltrim(category)), 'null') as category from items where category is not null and category != 'NOTES' order by category asc
        `);
        const categories = result.recordset.map(record => record.category);
        res.json(categories);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

router.get('/items', async (req, res) => {
  try {
    let category = req.query.category;
          let query = `
              SELECT *, 
              CASE WHEN (SELECT COUNT(1) FROM items_costing WHERE itemcode = I.itemcode) != 0 THEN 1 ELSE 0 END AS subitem_tag 
              FROM [restopos45].[dbo].[items] I WHERE itemname IS NOT NULL and (select count(1) from items_packages where sub_itemcode = I.itemcode) = 0 and (select count(1) from items_costing where sub_itemcode = I.itemcode) = 0
          `;
    
          // If a specific category is selected, filter by that category
          if (category && category !== 'ALL') {
              category = decodeURIComponent(category); // Decode the category parameter
              query += ' AND category = @category';
          }

      // Add ORDER BY clause to sort items alphabetically by itemname
      query += ' ORDER BY itemname';

      const pool = await sql.connect(config);
      const result = await pool.request()
          .input('category', sql.VarChar, category)
          .query(query);

      // Retrieve item codes from items_costing table
      const itemCostingQuery = `
          SELECT itemcode
          FROM [restopos45].[dbo].[items_costing]
      `;
      const itemCostingResult = await pool.request().query(itemCostingQuery);
      const subItemCodes = itemCostingResult.recordset.map(item => item.itemcode);

      // Filter out items with undesired categories and excluded item codes
      const filteredItems = result.recordset.filter(item => {
          const itemCategory = item.category ? item.category.trim().toLowerCase() : '';
          return itemCategory !== '' && !['notes', 'notes', 'notes'].includes(itemCategory) && !subItemCodes.includes(item.itemcode);
      });

      // Send the list of filtered and sorted items as a JSON response
      res.json(filteredItems);
  } catch (err) {
      console.error(err.message);
      res.status(500).send('Server Error');
  }
});

router.get('/checkForBillout', async (req, res) => {
  const { tableno } = req.query;

  try {
      const pool = await sql.connect(config);

      // Check if there are sales for the specified table number
      const isValidForBilloutResult = await pool.request()
          .input('tableno', sql.VarChar, tableno)
          .query(`
              SELECT COUNT(1) AS counter
              FROM sales
              WHERE sales_date = (
                  SELECT MAX(sales_date) 
                  FROM business_date_res 
                  WHERE zread_status = 0
              )
              AND machine_id = (
                select machine_id from machine_setup where mac_address = convert(varchar(255), (select serverproperty('MachineName')))    )
              AND table_no = @tableno
          `);
              // console.log(isValidForBilloutResult);
      const isValidForBillout = isValidForBilloutResult.recordset[0].counter > 0;

      if (isValidForBillout) {
          // Fetch summary data
          const summaryResult = await pool.request()
              .input('tableno', sql.VarChar, tableno)
              .query(`
                  SELECT 
                      DISTINCT sales_date,
                      ISNULL(RTRIM(LTRIM(table_no)), 'NULL') AS table_no,
                      ISNULL(RTRIM(LTRIM(cashierid)), 'NULL') AS cashierid,
                      ISNULL(no_of_pax, 0) AS no_of_pax,
                      (
                          SELECT SUM(subtotal) 
                          FROM sales 
                          WHERE sales_date = S.sales_date 
                          AND machine_id = S.machine_id 
                          AND table_no = S.table_no 
                          AND official_receipt IS NULL
                      ) AS subtotal,
                      (
                          SELECT billout 
                          FROM tableno 
                          WHERE table_no = S.table_no
                      ) AS billout_tag
                  FROM sales S
                  WHERE sales_date = (
                      SELECT MAX(sales_date) 
                      FROM business_date_res 
                      WHERE zread_status = 0
                  )
                  AND machine_id = (select machine_id from machine_setup where mac_address = convert(varchar(255), (select serverproperty('MachineName')))
                  )
                  AND table_no = @tableno 
                  AND status = 'O' 
                  AND official_receipt IS NULL
              `);

          const summary = summaryResult.recordset[0];

          // Fetch details data
          const detailsResult = await pool.request()
              .input('tableno', sql.VarChar, tableno)
              .query(`
                  SELECT 
                      ctr,
                      ISNULL(RTRIM(LTRIM(itemcode)), 'NULL') AS itemcode,
                      ISNULL(qty, 0) AS qty,
                      ISNULL(RTRIM(LTRIM(itemname)), 'NULL') AS itemname, 
                      ISNULL(selling_price, 0) AS selling_price,
                      ISNULL(subtotal, 0) AS subtotal
                  FROM sales
                  WHERE sales_date = (
                      SELECT MAX(sales_date) 
                      FROM business_date_res 
                      WHERE zread_status = 0
                  )
                  AND machine_id = (

                    select machine_id from machine_setup where mac_address = convert(varchar(255), (select serverproperty('MachineName')))

                  ) 
                  AND table_no = @tableno 
                  AND status = 'O' 
                  AND official_receipt IS NULL
              `);

          const detail = detailsResult.recordset;
          console.log("detail" ,detail);
          console.log("summary" ,summary);
          return res.status(200).json({ summary, detail });
      } else {
          return res.status(200).json({});
      }
  } catch (error) {
      console.error('Error executing SQL query:', error);
      return res.status(500).json({ message: 'Internal server error' });
  }
});


router.get('/billout', async (req, res) => {
  const { tableno } = req.query;

  try {
      const pool = await sql.connect(config);

      // Update the billout column for the specified table_no
      await pool.request()
          .input('tableno', sql.VarChar, tableno)
          .query(`
              UPDATE tableno 
              SET billout = 1 
              WHERE table_no = @tableno
          `);

      res.sendStatus(200);
  } catch (error) {
      console.error('Error updating billout:', error);
      res.status(500).json({ message: 'Internal server error' });
  }
});


module.exports = router;
