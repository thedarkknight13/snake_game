import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake_game/blank_pixel.dart';
import 'package:snake_game/food_pixel.dart';
import 'package:snake_game/highscore_tile.dart';
import 'package:snake_game/snake_pixel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SnakeDirection { up, down, right, left }

class _HomePageState extends State<HomePage> {
  final FocusNode _focusNode = FocusNode();
  // grid dimensions
  int rowSize = 10;
  int totalNumberOfSquares = 100;

  // game settings
  bool gameHasStarted = false;
  final _nameController = TextEditingController();

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

  // highscore list
  List<String> highScoreDocIds = [];
  late final Future? letsGetDocIds;

  @override
  void initState() {
    letsGetDocIds = getDocId();
    super.initState();
  }

  Future getDocId() async {
    await FirebaseFirestore.instance
        .collection("high_scores")
        .orderBy("score", descending: true)
        .limit(10)
        .get()
        .then(
          (value) => value.docs.forEach(
            (element) {
              highScoreDocIds.add(element.reference.id);
            },
          ),
        );
  }

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
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Enter Name",
                      ),
                      controller: _nameController,
                    )
                  ],
                ),
                actions: [
                  MaterialButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await submitScore();
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

  Future<void> submitScore() async {
    // get access to the database
    var database = FirebaseFirestore.instance;

    // add data to firebase
    await database.collection("high_scores").add({
      "name": _nameController.text,
      "score": currentScore,
    });
  }

  Future newGame() async {
    highScoreDocIds = [];
    await getDocId();
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
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowDown &&
              currentDirection != SnakeDirection.up) {
            currentDirection = SnakeDirection.down;
          } else if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowUp &&
              currentDirection != SnakeDirection.down) {
            currentDirection = SnakeDirection.up;
          } else if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              currentDirection != SnakeDirection.right) {
            currentDirection = SnakeDirection.left;
          } else if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowRight &&
              currentDirection != SnakeDirection.left) {
            currentDirection = SnakeDirection.right;
          }
        },
        child: Column(
          children: [
            // high score
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // user current score
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Current Score"),
                        Text(
                          "$currentScore",
                          style: const TextStyle(fontSize: 36),
                        ),
                      ],
                    ),
                  ),

                  // high scores, top 5 or top 10
                  Expanded(
                    child: gameHasStarted
                        ? Container()
                        : FutureBuilder(
                            future: letsGetDocIds,
                            builder: (context, snapshot) {
                              return ListView.builder(
                                itemCount: highScoreDocIds.length,
                                itemBuilder: (context, index) {
                                  return HighscoreTile(
                                    documentId: highScoreDocIds[index],
                                  );
                                },
                              );
                            },
                          ),
                  )
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
      ),
    );
  }
}
