
const checkForBillout = asyncHandler(async (req, res) => {
    const { tableno } = req.query;
    const isValidForBillout = await executeQueryWithParams(
    );
    `select count(1) as counter
from sales
where sales_date = (select max (sales_date) from business_date_res where zread_status = 0)
and machine_id = (SELECT terminal_number FROM sys_setup)`,
        { tableno }
    if (isValidForBillout[0].counter > 0) {
        const summary = await executeQueryWithParams(
            `select distinct sales_date,
from sales S
isnull(rtrim(1trim(table_no)), 'NULL') as table_no,
isnull(rtrim(1trim(cashierid)), 'NULL') as cashierid,
isnull(no_of_pax, 0) as no_of_pax,
(select sum(subtotal) from sales where sales_date = S.sales_date and machine_id = S.machine_id and 
table_no = S.table_no and official_receipt is null) as subtotal, (select billout from tableno where table_no = S.table_no) as billout_tag
from sales S
where sales_date = (select max(sales_date) from business_date_res where zread_status = 0)
and machine_id = (SELECT terminal_number FROM sys_setup)
and table_no = @tableno and status = '0' and official_receipt is null`,
            { tableno });
        const details = await executeQueryWithParams(

            `select ctr,
isnull(rtrim(ltrim(itemcode)), 'NULL') as itemcode,
isnull(qty, 0) as qty,
isnull(rtrim(1trim(itemname)), 'NULL') as itemname, isnull(selling price, 0) as selling_price,
isnull(subtotal, 0) as subtotal
from sales
where sales_date = (select max(sales_date) from business_date_res where zread_status = 0)
and machine_id = (SELECT terminal_number FROM sys_setup) and table_no = @tableno and status = '0' and official_receipt is null`,
            { tableno });
        return res.status(200).json({ summary: summary[0], details: details });
    } else {
        return res.status(200).json({});
    }
});
module.exports = { getTable, checkForBillout };



const { content, summary, add_order } = req.body;
  let so_number = "";

  if (add_order === 0) {
    await executeQuery("EXEC sp_so_number_handler");

    const generate_so_number = await executeQuery(
      "SELECT last_or FROM business_date_res"
    );
    so_number = generate_so_number[0].last_or;
  } else if (add_order === 1) {
    const getExistingSo = await executeQuery(
      `select so_number from so_header where table_no = '${summary.table_no}' and posted = 0`
    );
    so_number = getExistingSo[0].so_number;
  }

  await executeQueryWithParams(
    `EXEC sp_add_to_so_detail '${req.session.user}',
                              '${so_number}',
                              '${req.session.machine_id}',
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
                              ${add_order}`,
    content
  );

  await executeQueryWithParams(
    `EXEC sp_add_to_so_header '${so_number}',
                              '${req.session.machine_id}',
                              '${req.session.user}',
                              @total,
                              @table_no,
                              @order_service
  `,
    summary
  );

  await executeQuery(
    `UPDATE tableno
         SET occupied = 0, status = 'O' WHERE table_no = '${summary.table_no}'`
  );

  await executeQuery("update notification set notif = 1");

res.sendStatus(200);



