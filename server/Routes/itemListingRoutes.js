const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');

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
      let query = "SELECT * , case  when (select count(1) from items_costing where itemcode = I.itemcode) != 0 then 1 else 0  end as subitem_tag FROM [restopos45].[dbo].[items] I " ;
  
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
  


module.exports = router;
