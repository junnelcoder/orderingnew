const express = require('express');
const router = express.Router();
const sql = require('mssql');
const config = require('../server.js');
const net = require('net');
const config2 = require('../config.json');
const { ThermalPrinter, PrinterTypes, CharacterSet, BreakLine } = require('node-thermal-printer');

  
const initializePrinter = (ip) => {
    return new ThermalPrinter({
      type: PrinterTypes.RONGTA,
      interface:   `tcp://${ip}`,
      characterSet: CharacterSet.PC852_LATIN2,
      lineCharacter: "-",
      breakLine: BreakLine.NONE,
      options: {
        timeout: 3000,
      },
    });
  };
  const orderType = (code) => {
    let type = "";
  
    if (code === "DI") {
      type = "DINE IN";
    } else if (code === "TO") {
      type = "TAKE OUT";
    } else if (code === "DE") {
      type = "DELIVERY";
    } else if (code === "PU") {
      type = "PICK UP";
    }
  
    return type;
  };
  
  
  const layoutFor58mm = async (storeName, printerConfig, data1, data2) => {
    printerConfig.setTextNormal();
    printerConfig.setTypeFontA();
    printerConfig.alignCenter();
    printerConfig.println(storeName);
    printerConfig.println("ORDER SLIP");
    printerConfig.println("Date: " + formatDate());
    printerConfig.bold(true);
    printerConfig.println("SO NUMBER: " + data1.soNo);
    printerConfig.bold(false);
    printerConfig.print("-".repeat(32));
  
    if (
      data1.tableNo &&
      data1.orderType &&
      !String(data1.tableNo).includes("QS")
    ) {
      printerConfig.bold(true);
      printerConfig.println("- - - TABLE NO - - - " + data1.tableNo);
      printerConfig.bold(false);
      printerConfig.print("-".repeat(32));
    } else {
      printerConfig.bold(true);
      printerConfig.println(
        `- - - ORDER FOR: ${extractNickname(data1.tableNo, "QS-")} - - -` 
      );
      printerConfig.bold(false);
      printerConfig.print("-".repeat(32));
    }
  
    printerConfig.println("Order Taker:  " + data1.user);
  
    printerConfig.cut({ verticalTabAmount: 1 });
    printerConfig.beep();
  
    try {
      await printerConfig.execute({ waitForResponse: false });
    } catch (err) {
      console.error("Print failed!", err);
    }
  };
  
  const extractNickname = (text, textToExclude) => {
    const index = text.indexOf(textToExclude);
  
    if (index === -1) {
      return text;
    }
  
    return text.slice(0, index) + text.slice(index + textToExclude.length);
  };
  
  const checkPrinterConnection = async (printerConfig) => {
    try {
      let isConnected = await printerConfig.isPrinterConnected();
  
      if (isConnected) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      console.error("Error: ", e);
    }
  };
  
  const formatDate = () => {
    const currentDate = new Date();
  
    const options = {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    };
  
    const formattedDate = new Intl.DateTimeFormat("en-US", options).format(
      currentDate
    );
  
    return formattedDate;
  };
  
  const printOrderSlip = async (summary, items) => {
    try {
        const pool = await sql.connect(config);
    const getPrinterConfig= await pool.request().query(
        "SELECT ISNULL(setup_printer_tag, NULL) as printer_type, ISNULL(RTRIM(LTRIM(ip_address_printer)), 'NULL') as printer_ip FROM sys_setup"
      );
      console.log(getPrinterConfig);
      const printerDetails = {
        printer_type: getPrinterConfig.recordset[0].printer_type,
        printer_ip: getPrinterConfig.recordset[0].printer_ip,
      };
  
      if (
        printerDetails.printer_ip &&
        String(printerDetails.printer_ip).toUpperCase() !== "NULL"
      ) {
        const printer = initializePrinter(printerDetails.printer_ip);
  
        if (checkPrinterConnection(printer)) {
          if (printerDetails.printer_type === 1) {
            layoutFor58mm("ZANKPOS", printer, summary, items);
          } else {
            console.log("This printer type is not available.");
            return 0;
          }
        } else {
          return 0;
        }
      } else {
        return 0;
      }
    } catch (e) {
      console.error("Error: ", e);
    }
  };
  
  module.exports = { printOrderSlip };