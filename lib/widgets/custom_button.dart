import 'package:flutter/material.dart';
import 'package:mp_tictactoe/responsive/responsive.dart';


class CustomButton extends StatelessWidget {
  final VoidCallback onTap;

  final String text;
  const CustomButton({Key? key, required this.onTap, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    return Responsive(
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.blue,
              blurRadius: 5,
              spreadRadius: 0,
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap, 
          child: Text(
              text, 
              style: const TextStyle(
                fontSize: 16,
              ),),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(
              width, 
              50,
            ),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }
}