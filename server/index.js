const express = require('express');
const http = require('http');
const mongoose = require('mongoose');

const Room = require('./models/room.js');


const app = express();
const port = process.env.PORT || 3000;
var server = http.createServer(app);

var io = require("socket.io")(server);

app.use(express.json());


const DB = "Your MongoDB Cluster";


io.on("connection", (socket) => {
    console.log("Socket.io Connected !");
    socket.on("createRoom", async ({ nickname, solution }) => {
        console.log("socket connected !");
        console.log(nickname);
        console.log("1. " + socket.id);

        try{

            // room is created
            // player is stored in the room

            let room = new Room();
            let player = {
                socketID: socket.id,
                nickname, //nickname: nickname,
                playerType: 'X',
            };
            room.players.push(player);
            room.turn = player;

            room.solution = solution;

            //Save data to MongoDB

            room = await room.save(); //It will return additional properties like _id of the room

            const roomID = room._id.toString(); //Auto generated id will be saved here

                //eğer burada, serverda bir emit falan yaparsak tüm oyunlara gider
            socket.join(roomID); //Böylece bu odaya katılıyoruz ve başka yere musallat olmuyoruz


            //tell our client that room has been created
            // player is taken to the next screen

                //io -> send/manipulate data to everyone
                //socket -> send/manipulate data to yourself

            io.to(roomID).emit('createRoomSuccess', room);

        } catch (e) {
            console.log(e);
        }
        
    });

    socket.on('joinRoom', async ({nickname, roomId}) => {
        try {

            if(!roomId.match(/^[0-9a-fA-F]{24}$/)) {
                socket.emit('errorOccurred', 'Please enter a valid room ID !');
                return;
            }

            let room = await Room.findById(roomId);

            if(room.isJoin) {
                let player = {
                    nickname,
                    socketID: socket.id,
                    playerType: 'O'
                };

                socket.join(roomId);
                room.players.push(player);
                room.isJoin = false;
                room = await room.save();
                io.to(roomId).emit('joinRoomSuccess', room);
                io.to(roomId).emit('updatePlayers', room.players);
                io.to(roomId).emit('updateRoom', room);

            } else {
                socket.emit('errorOccurred', 'The game is in progress, try again later !');
            }

        } catch (e) {
            console.log(e);
        }
    });

    socket.on('tapEnter', async ({word, roomId}) => {
        try {
            let room = await Room.findById(roomId);

            if(room.turnIndex == 0) {
                room.turn = room.players[1];
                room.turnIndex = 1;
            }
            else {
                room.turn = room.players[0];
                room.turnIndex = 0;
            }

            room = await room.save();

            io.to(roomId).emit('opponentEnter', {
                word,
                room,
            });
            io.to(roomId).emit('updateRoom', room);

        } catch (e) {
            console.log(e);
        }
    })

    socket.on('tap', async ({index, roomId}) => {
        try {
            let room = await Room.findById(roomId);

            let choice = room.turn.playerType; // x or o

            if(room.turnIndex == 0) {
                room.turn = room.players[1];
                room.turnIndex = 1;
            }
            else {
                room.turn = room.players[0];
                room.turnIndex = 0;
            }

            room = await room.save();

            io.to(roomId).emit('tapped', {
                index,
                choice,
                room,
            });

        } catch (e) {
            console.log(e);
        }
    })

    socket.on('roundFinished', async ({winnerSocketId, roomId, puan}) => {
        try {

            let room = await Room.findById(roomId);
            let player = room.players.find((playerr) => playerr.socketID == winnerSocketId);
            player.points += puan;

            room = await room.save();

            if(player.points >= 200) {
                io.to(roomId).emit('pointIncrease', player);
                io.to(roomId).emit('endGame', player);
            } else {
                io.to(roomId).emit('pointIncrease', player);
                io.to(roomId).emit('looserTespit', player);
            }

        } catch (e) {
            console.log(e);
        }
    });

    socket.on('newSolutionDispenser', async ({roomId, word}) => {
        try {
            let room = await Room.findById(roomId);

            room.solution = word;

            io.to(roomId).emit('updateRoom', room);

            room = await room.save();

        } catch (e) {
            console.log(e);
        }
    })

});

mongoose.connect(DB).then(() => {
    console.log('MongoDB Connection Successfull !');
}).catch((e) => {
    console.log(e);
});

server.listen(port, '0.0.0.0', () => {
    console.log('Server Started !');

});

