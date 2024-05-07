import 'dart:math';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:mp_tictactoe/app_w/app_colors.dart';
import 'package:mp_tictactoe/resources/socket_client.dart';
import 'package:mp_tictactoe/views/scoreboard.dart';
import 'package:mp_tictactoe/wordle/data/word_list.dart';
import 'package:mp_tictactoe/wordle/widgets/keyboardA.dart';
import 'package:mp_tictactoe/wordle/wordle.dart';

//import 'package:flutter/material.dart';
import 'package:mp_tictactoe/provider/room_data_provider.dart';
import 'package:mp_tictactoe/resources/socket_methods.dart';
//import 'package:mp_tictactoe/views/scoreboard.dart';
//import 'package:mp_tictactoe/views/tictactoe_board.dart';
import 'package:mp_tictactoe/views/waiting_lobby.dart';
import 'package:provider/provider.dart';

enum GameStatus { playing, submitting, lost, won}

class WordleScreen extends StatefulWidget {
  static String routeName = '/game';
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {

  final SocketMethods _socketMethods = SocketMethods();

  
  GameStatus _gameStatus = GameStatus.playing;

  final List<Word> _board = List.generate(
    6,
    (_) => Word(letters: List.generate(5, (_) => Letter.empty())),
  );

  final List<List<GlobalKey<FlipCardState>>> _flipCardkeys = List.generate(
    6, 
    (_) => List.generate(5, (_) => GlobalKey<FlipCardState>()),
  );
  int _currentWordIndex = 0;

  Word? get _currentWord => _currentWordIndex < _board.length ? _board[_currentWordIndex] : null;

  Word _solution = Word.fromString("IMDAT");

  final Set<Letter> _keyboardLetters = {};

  bool controller = true;

  int puan = 0;

  bool winRoundController = false;


  @override
  void initState() {
    super.initState();
    opponentEnterListener();
    looserListener();
    _socketMethods.updateRoomListener(context);
    _socketMethods.updatePlayersStateListener(context);
    _socketMethods.pointIncreaseListener(context);
    _socketMethods.endGameListener(context);
  }

  @override
  Widget build(BuildContext context) {

    RoomDataProvider roomDataProvider = Provider.of<RoomDataProvider>(context);

    print(Provider.of<RoomDataProvider>(context).roomData['solution']);

    _solution = Word.fromString(Provider.of<RoomDataProvider>(context).roomData['solution']);

    return Scaffold(
      body: roomDataProvider.roomData['isJoin'] 
          ? const WaitingLobby() 
          :  SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Scoreboard(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Board(board: _board, flipCardKeys: _flipCardkeys),
                      const SizedBox(height: 10),
                      Text('${roomDataProvider.roomData['turn']['nickname']}\'s turn', style: const TextStyle(fontSize: 30),),
                      const SizedBox(height: 10),
                      Keyboard(
                        onKeyTapped: _onKeyTapped, 
                        onDeleteTapped: _onDeleteTapped, 
                        onEnterTapped: _onEnterTapped,
                        letters: _keyboardLetters,
                      ),
                    ],
                  ),
                ],
              ),
          ),
    );
  }

  void looserListener() {
    print('looser giris');
    _socketMethods.socketClient.on('looserTespit', (playerData) {
      print(playerData['socketID']);
      print(_socketMethods.socketClient.id);
        
        if(playerData['socketID'] != _socketMethods.socketClient.id) {
          print('NERESİDUR - - ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              dismissDirection: DismissDirection.none,
              duration: const Duration(days: 1),
              backgroundColor: Colors.redAccent[200],
              content: Text(
                'You lost!',
                style: const TextStyle(color: Colors.white),
              ),
              action: SnackBarAction(
                onPressed: _restart,
                textColor: Colors.white,
                label: "Next Round",
              ),
            ),
          );
        }
        if(playerData['socketID'] == _socketMethods.socketClient.id) {
            print('Ha Burasidur');
        }
    });
    print('looser cikis');
  }

  Future<void> opponentEnterListener() async {
    print('66');

    _socketMethods.socketClient.on('opponentEnter', (data) async {
      print('77');
      try {
        if(Provider.of<RoomDataProvider>(context, listen: false).roomData['turn']['socketID'] != _socketMethods.socketClient.id){
          print('88');

          
          
          String oppWord = data['word'];
          print('99');

          setState(() { 
            _currentWord?.addLetter(oppWord[0]);
            _currentWord?.addLetter(oppWord[1]);
            _currentWord?.addLetter(oppWord[2]);
            _currentWord?.addLetter(oppWord[3]);
            _currentWord?.addLetter(oppWord[4]);
          });
          print('10');

          _onEnterTappedForOpponent(_currentWord);
          
          print('11');
          
        }
      } catch (e) {
        print(e);
      }
      
      print('AAAAAAAAAAAAAAAAAAA3');
    });
  }

  Future<void> _onEnterTappedForOpponent(Word? _currentWord) async {
    
    if (_gameStatus == GameStatus.playing &&
        _currentWord != null &&
        !_currentWord!.letters.contains(Letter.empty())) {
      _gameStatus = GameStatus.submitting;

      

      for (var i = 0; i < _currentWord!.letters.length; i++) {
        final currentWordLetter = _currentWord!.letters[i];
        final currentSolutionLetter = _solution.letters[i];

        setState(() {
          if (currentWordLetter == currentSolutionLetter) {
            _currentWord!.letters[i] =
                currentWordLetter.copyWith(status: LetterStatus.correct);
          } else if (_solution.letters.contains(currentWordLetter)) {
            _currentWord!.letters[i] =
                currentWordLetter.copyWith(status: LetterStatus.inWord);
          } else {
            _currentWord!.letters[i] =
                currentWordLetter.copyWith(status: LetterStatus.notInWord);
          }
        });

        final letter = _keyboardLetters.firstWhere(
          (e) => e.val == currentWordLetter.val,
          orElse: () => Letter.empty(),
        );
        if (letter.status != LetterStatus.correct) {
          _keyboardLetters.removeWhere((e) => e.val == currentWordLetter.val);
          _keyboardLetters.add(_currentWord!.letters[i]);
        }
        await Future.delayed(
          const Duration(milliseconds: 150),
          () => _flipCardkeys[_currentWordIndex][i].currentState?.toggleCard(),
        );

      }
      print('3');

      controller = false;
      _checkIfWinOrLoss();
    }
  }

  void _onKeyTapped(String val) {
    if (_gameStatus == GameStatus.playing) {
      setState(() => _currentWord?.addLetter(val));
    }
  }

  void _onDeleteTapped() {
    if (_gameStatus == GameStatus.playing) {
      setState(() => _currentWord?.removeLetter());
    }
  }

  Future<void> _onEnterTapped() async {
    
    if (_gameStatus == GameStatus.playing &&
        _currentWord != null &&
        !_currentWord!.letters.contains(Letter.empty())) {
      _gameStatus = GameStatus.submitting;

      print('1');
      _socketMethods.tapEnter(_currentWord!.wordString, Provider.of<RoomDataProvider>(context,listen: false).roomData['_id']);
      print('2');

      for (var i = 0; i < _currentWord!.letters.length; i++) {
        final currentWordLetter = _currentWord!.letters[i];
        final currentSolutionLetter = _solution.letters[i];

        setState(() {
          if (currentWordLetter == currentSolutionLetter) {
            _currentWord!.letters[i] =
                currentWordLetter.copyWith(status: LetterStatus.correct);
                puan += 10;
          } else if (_solution.letters.contains(currentWordLetter)) {
            _currentWord!.letters[i] =
                currentWordLetter.copyWith(status: LetterStatus.inWord);
                puan += 5;
          } else {
            _currentWord!.letters[i] =
                currentWordLetter.copyWith(status: LetterStatus.notInWord);
          }
        });

        final letter = _keyboardLetters.firstWhere(
          (e) => e.val == currentWordLetter.val,
          orElse: () => Letter.empty(),
        );
        if (letter.status != LetterStatus.correct) {
          _keyboardLetters.removeWhere((e) => e.val == currentWordLetter.val);
          _keyboardLetters.add(_currentWord!.letters[i]);
        }

        await Future.delayed(
          const Duration(milliseconds: 150),
          () => _flipCardkeys[_currentWordIndex][i].currentState?.toggleCard(),
        );
        
      }
      print('3');

      controller = false;
      _checkIfWinOrLoss();
    }

    //_socketMethods.tapEnter(_currentWord!.wordString, Provider.of<RoomDataProvider>(context,listen: false).roomData['_id']);

  }

  void _checkIfWinOrLoss() {
    print('4');

    if(controller) {
      return;
    }

    print('4.5');

    RoomDataProvider roomDataProvider = Provider.of<RoomDataProvider>(context,listen: false);

    if (_currentWord!.wordString == _solution.wordString) {
      //KAZANMA

      int toplamPuan = puan + ((5-_currentWordIndex)*10);
      

      if(roomDataProvider.roomData['turn']['socketID'] != _socketMethods.socketClient.id) {
        winRoundController = true;
        _socketMethods.socketClient.emit('roundFinished', {
          'winnerSocketId': _socketMethods.socketClient.id,
          'roomId': roomDataProvider.roomData['_id'],
          'puan' : toplamPuan,
        });

        _socketMethods.socketClient.emit('newSolutionDispenser', {
          'roomId': roomDataProvider.roomData['_id'],
          'word' : fiveLetterWords[Random().nextInt(fiveLetterWords.length)].toUpperCase(),
        });

        

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            dismissDirection: DismissDirection.none,
            duration: const Duration(days: 1),
            backgroundColor: correctColor,
            content: const Text(
              "You won!",
              style: TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              onPressed: _restart,
              textColor: Colors.white,
              label: "Next Round",
            ),
          ),
        );

      }

      _gameStatus = GameStatus.won;

    } else if (_currentWordIndex + 1 >= _board.length) {
      
      _gameStatus = GameStatus.lost;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.none,
          duration: const Duration(days: 1),
          backgroundColor: Colors.redAccent[200],
          content: Text(
            'Draw!',
            style: const TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            onPressed: _restart,
            textColor: Colors.white,
            label: "Next Round",
          ),
        ),
      );

      if(_socketMethods.socketClient.id == roomDataProvider.player1.socketID) {
          _socketMethods.socketClient.emit('newSolutionDispenser', {
              'roomId': roomDataProvider.roomData['_id'],
              'word' : fiveLetterWords[Random().nextInt(fiveLetterWords.length)].toUpperCase(),
          });
      }
      

    } else {
      _gameStatus = GameStatus.playing;
    }
    print('5');

    controller = true;
    _currentWordIndex += 1;


  }

  void _restart() {
    setState(() {
      _gameStatus = GameStatus.playing;
      _currentWordIndex = 0;
      controller = true;
      puan = 0;
      winRoundController = false;

      _board
        ..clear()
        ..addAll(
          List.generate(
            6,
            (_) => Word(letters: List.generate(5, (_) => Letter.empty())),
          ),
        );

      _flipCardkeys
        ..clear()
        ..addAll(
          List.generate(
            6, 
            (_) => List.generate(5, (_) => GlobalKey<FlipCardState>()),
          ),
        );
      _keyboardLetters.clear();
    });
  }

  Future<void> _awaitliFunc(int i) async {
    await Future.delayed(
          const Duration(milliseconds: 150),
          () => _flipCardkeys[_currentWordIndex][i].currentState?.toggleCard(),
    );
  }

  
}


