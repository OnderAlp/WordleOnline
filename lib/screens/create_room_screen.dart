

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mp_tictactoe/responsive/responsive.dart';
import 'package:mp_tictactoe/widgets/custom_button.dart';
import 'package:mp_tictactoe/widgets/custom_text.dart';
import 'package:mp_tictactoe/widgets/custom_textfield.dart';
import 'package:mp_tictactoe/resources/socket_methods.dart';
import 'package:mp_tictactoe/wordle/data/word_list.dart';
import 'package:mp_tictactoe/wordle/models/word_model.dart';


class CreateRoomScreen extends StatefulWidget {
  static String routeName = '/create-room';

  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final SocketMethods _socketMethods = SocketMethods();

  Word _solution = Word.fromString(fiveLetterWords[Random().nextInt(fiveLetterWords.length)].toUpperCase(),);

  @override
  void initState() {
    super.initState();
    _socketMethods.createRoomSuccessListener(context);
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
  }
  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Scaffold(
      //resizeToAvoidBottomInset: false,
      body: Responsive(
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CustomText(
                shadows: [
                  Shadow(
                    blurRadius: 40,
                    color: Colors.blue,
                  ),
                ], 
                text: 'Create Room', 
                fontSize: 70,
              ),
              SizedBox(height: size.height * 0.08),
              CustomTextField(controller: _nameController, hintText: 'Enter Your Nickname'),
              SizedBox(height: size.height * 0.045),
              CustomButton(
                  onTap: () => _socketMethods.createRoom(
                      _nameController.text,
                      _solution.wordString,
                    ), 
                  text: 'Create')
            ],
          ),
        ),
      ),
    );
  }
}