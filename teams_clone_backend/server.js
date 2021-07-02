const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();
const http = require('http');
const port = 3000;
const dotenv = require('dotenv');
const Socket = require('socket.io');
const WebSockets = require("./utils/WebSockets.js");
const socketio = Socket();
dotenv.config();

mongoose.set('useNewUrlParser', true);
mongoose.set('useFindAndModify', false);
mongoose.set('useCreateIndex', true);

app.use(cors());
app.use(require('morgan')('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

//import routes
const chatRoute = require('./routes/chatRoom');
app.use('/chat', chatRoute);

const usersRoute = require('./routes/users');
app.use('/users', usersRoute);

const eventsRoute = require('./routes/events');
app.use('/events', eventsRoute);

const imagesRoute = require('./routes/images');
app.use('/images', imagesRoute);

//db
async function connectDB() {
  await mongoose.connect("mongodb+srv://vasugupta:vasugupta@cluster0.uhnx9.mongodb.net/Cluster0?retryWrites=true&w=majority", { useNewUrlParser: true, useUnifiedTopology: true });
  console.log("db connected");
}
connectDB();

//home page
app.get('/', (req, res) => {
  res.send('Welcome to Teams clone by Vasu Gupta');
})

const server = http.createServer(app);
global.io = socketio.listen(server);
global.io.on('connection', WebSockets.connection)
server.listen(process.env.PORT || port);