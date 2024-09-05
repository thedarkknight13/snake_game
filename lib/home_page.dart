import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:snake_game/blank_pixel.dart';
import 'package:snake_game/food_pixel.dart';
import 'package:snake_game/snake_pixel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SnakeDirection { up, down, right, left }

class _HomePageState extends State<HomePage> {
  // grid dimensions
  int rowSize = 10;
  int totalNumberOfSquares = 100;

  bool gameHasStarted = false;

  // user score
  int currentScore = 0;

  // snake position
  List<int> snakePos = [
    0,
    1,
    2,
  ];

  // snake direction is initially to the right
  var currentDirection = SnakeDirection.right;

  // food position
  int foodPos = 55;

  // start the game
  void startGame() {
    gameHasStarted = true;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        // keep the snake moving
        moveSnake();

        // check if the game is over
        if (gameOver()) {
          timer.cancel();

          // display message to the user
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: const Text("Game over"),
                content: Column(
                  children: [
                    Text("Your score is: $currentScore"),
                    const TextField(
                      decoration: InputDecoration(
                        hintText: "Enter Name",
                      ),
                    )
                  ],
                ),
                actions: [
                  MaterialButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      submitScore();
                      newGame();
                    },
                    color: Colors.pink,
                    child: const Text("Submit"),
                  )
                ],
              );
            },
          );
        }
      });
    });
  }

  void submitScore() {}

  void newGame() {
    setState(() {
      snakePos = [
        0,
        1,
        2,
      ];
      foodPos = 55;
      currentDirection = SnakeDirection.right;
      gameHasStarted = false;
      currentScore = 0;
    });
  }

  void eatFood() {
    currentScore++;
    // making sure the new food is not where the snake is
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(totalNumberOfSquares);
    }
  }

  void moveSnake() {
    switch (currentDirection) {
      case SnakeDirection.up:
        {
          // add new head
          if (snakePos.last < rowSize) {
            snakePos.add(snakePos.last - rowSize + totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last - rowSize);
          }
        }
        break;
      case SnakeDirection.down:
        {
          // add new head
          if (snakePos.last + rowSize > totalNumberOfSquares) {
            snakePos.add(snakePos.last + rowSize - totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last + rowSize);
          }
        }
        break;
      case SnakeDirection.right:
        {
          // add new head
          // if snake is at right wall, need to re-adjust
          if (snakePos.last % rowSize == 9) {
            snakePos.add(snakePos.last + 1 - rowSize);
          } else {
            snakePos.add(snakePos.last + 1);
          }
        }
        break;
      case SnakeDirection.left:
        {
          // add new head
          // if snake is at left wall, need to re-adjust
          if (snakePos.last % rowSize == 0) {
            snakePos.add(snakePos.last - 1 + rowSize);
          } else {
            snakePos.add(snakePos.last - 1);
          }
        }
        break;
    }
    // check if snake is eating food
    if (snakePos.last == foodPos) {
      eatFood();
    } else {
      // remove tail
      snakePos.removeAt(0);
    }
  }

  //game over
  bool gameOver() {
    // the game is over when the snake runs into itself
    // this occurs when there is a duplicate position in the snake position list

    // this list is the body of the snake (no head)
    List<int> bodySnake = snakePos.sublist(0, snakePos.length - 1);
    if (bodySnake.contains(snakePos.last)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // high score
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Current Score"),
                    Text(
                      "$currentScore",
                      style: const TextStyle(fontSize: 36),
                    ),
                  ],
                ),
                // user current score

                // high scores, top 5 or top 10
                const Text("highscores..."),
              ],
            ),
          ),

          // game grid
          Expanded(
            flex: 3,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0 &&
                    currentDirection != SnakeDirection.up) {
                  currentDirection = SnakeDirection.down;
                } else if (details.delta.dy < 0 &&
                    currentDirection != SnakeDirection.down) {
                  currentDirection = SnakeDirection.up;
                }
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 0 &&
                    currentDirection != SnakeDirection.left) {
                  currentDirection = SnakeDirection.right;
                } else if (details.delta.dx < 0 &&
                    currentDirection != SnakeDirection.right) {
                  currentDirection = SnakeDirection.left;
                }
              },
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: rowSize,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalNumberOfSquares,
                itemBuilder: (context, index) {
                  if (snakePos.contains(index)) {
                    return const SnakePixel();
                  } else if (foodPos == index) {
                    return const FoodPixel();
                  }
                  return const BlankPixel();
                },
              ),
            ),
          ),

          // play button
          Expanded(
            child: Center(
              child: MaterialButton(
                color: gameHasStarted ? Colors.grey : Colors.pink,
                onPressed: gameHasStarted ? () {} : startGame,
                child: const Text("PLAY"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
