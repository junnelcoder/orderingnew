const express = require('express');
const app = express();
const session = require('express-session');
const sql = require('mssql');
const bodyParser = require('body-parser');
const http = require('http');
const path = require('path');
const fs = require('fs');
const os = require('os');
const cors = require('cors');
const ip = require('ip');
// Load configuration file
const config = require('./config.json');

app.use(session({
  secret: config.key.secret,
  resave: false,
  saveUninitialized: true,
}));

// Add CORS middleware
app.use(cors());
app.use(bodyParser.json());

// Serve static files (images) from the 'images' directory
app.use('/images', express.static(path.join(__dirname, 'images')));

// Your other routes
const item = require('./Routes/itemListingRoutes');
const auth = require('./Routes/authenticationRoute');
const crud = require('./Routes/orderCrud');
app.use('/api', item);
app.use('/api', auth);
app.use('/api', crud);

// Endpoint to serve images based on itemcode
app.get('/api/image/:itemcode', (req, res) => {
  const itemcode = req.params.itemcode;
  const currentDirectory = process.cwd();
  const imagePath = path.join(currentDirectory, 'images', `${itemcode}.png`);

  // Check if the file exists
  fs.access(imagePath, fs.constants.F_OK, (err) => {
    if (err) {
      // If the file doesn't exist, send the default image
      const defaultImagePath = path.join(currentDirectory, 'images', 'DEFAULT.png');
      res.sendFile(defaultImagePath);
      // Clear the screen after sending the response
      console.clear();
      // Trigger connectToSqlServer after clearing the screen
      connectToSqlServer();
    } else {
      // If the file exists, send it
      res.sendFile(imagePath);
    }
  });
});


// Function to get the IP address of the Wi-Fi adapter
const getWiFiIPAddress = () => {
  const interfaces = os.networkInterfaces();
  let wifiIP = null;

  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        if (name.startsWith('wlan') || name.startsWith('Wi-Fi')) {
          wifiIP = iface.address;
        }
      }
    }
  }

  return wifiIP;
};

// Create a function to start the server

const startServer = () => {
  const server = http.createServer(app);

  let ipAddr = getWiFiIPAddress();
  const port = 3009;

  if (!ipAddr) {
    ipAddr = ip.address(); // Fallback to Ethernet IP address
    if (!ipAddr) {
      console.error('No Wi-Fi or Ethernet IP address found.');
      return;
    }
  }

  server.listen(port, ipAddr, () => {
    console.log(`Server is running at http://${ipAddr}:${port}`);
  });

  // Handle server errors
  server.on('error', (error) => {
    console.error('Server error:', error);
    console.log('Restarting server...');
    // Restart server after 5 seconds
    setTimeout(startServer, 5000);
  });
};

// Start the server
startServer();

// Connect to SQL Server
const connectToSqlServer = () => {
  // console.log('Attempting to connect to SQL Server with config:', config.db);
  sql.connect(config.db)
    .then(() => {
      console.log('Connected to SQL Server');
    })
    .catch((err) => {
      console.error('Error connecting to SQL Server:', err);
      console.log('Retrying connection...');
      // Retry connection after 5 seconds
      setTimeout(connectToSqlServer, 5000);
    });
};

// Attempt to connect to SQL Server
connectToSqlServer();
