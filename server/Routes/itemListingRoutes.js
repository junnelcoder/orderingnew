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
          FROM [restopos45].[dbo].[items] I 
      `;

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





module.exports = router;
