import 'dart:async';
import 'dart:math';

import 'package:flappy_birds_game/widgets/my_barrier.dart';
import 'package:flappy_birds_game/widgets/my_bird.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static double birdYaxis = 0;
  double time = 0;
  double height = 0;
  double initialHeight = birdYaxis;
  bool gameHasStarted = false;
  static double barrierXone = 1;
  double barrierXtwo = barrierXone + 1.5;

  // Score Variables
  int score = 0;
  int bestScore = 0;

  // Barrier Pass Flags
  bool barrierOnePassed = false;
  bool barrierTwoPassed = false;

  // Timer
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    gameTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  // Load Best Score from SharedPreferences
  void _loadBestScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('bestScore') ?? 0;
    });
  }

  // Update Best Score if Current Score is Higher
  void _updateBestScore() async {
    if (score > bestScore) {
      bestScore = score;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt('bestScore', bestScore);
      setState(() {}); // Update the UI
    }
  }

  // Reset Game to Initial State
  void _resetGame() {
    setState(() {
      birdYaxis = 0;
      time = 0;
      height = 0;
      initialHeight = birdYaxis;
      barrierXone = 1;
      barrierXtwo = barrierXone + 1.5;
      score = 0;
      barrierOnePassed = false;
      barrierTwoPassed = false;
    });
  }

  // Jump Function
  void jump() {
    setState(() {
      time = 0;
      initialHeight = birdYaxis;
    });
  }

  // Start Game Function
  void startGame() {
    gameHasStarted = true;
    score = 0; // Reset score at the start of the game
    barrierOnePassed = false;
    barrierTwoPassed = false;

    gameTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      time += 0.05;
      height = -4.9 * time * time + 2.8 * time;
      setState(() {
        birdYaxis = initialHeight - height;
      });

      setState(() {
        // Update barrierXone
        if (barrierXone < -1.5) {
          barrierXone += 3; // Ensures it's placed ahead by 3 units
          barrierOnePassed = false; // Reset pass flag
          // Optionally, randomize gap here
        } else {
          barrierXone -= 0.05;
        }

        // Update barrierXtwo
        if (barrierXtwo < -1.5) {
          barrierXtwo += 3; // Ensures it's placed ahead by 3 units
          barrierTwoPassed = false; // Reset pass flag
          // Optionally, randomize gap here
        } else {
          barrierXtwo -= 0.05;
        }
      });

      // Check if bird has passed barrierXone
      if (!barrierOnePassed && barrierXone < 0) {
        score += 1;
        barrierOnePassed = true;
        _updateBestScore();
      }

      // Check if bird has passed barrierXtwo
      if (!barrierTwoPassed && barrierXtwo < 0) {
        score += 1;
        barrierTwoPassed = true;
        _updateBestScore();
      }

      // Collision Detection
      _checkCollision();

      if (birdYaxis > 1) {
        timer.cancel();
        gameHasStarted = false;
        _showGameOverDialog();
      }
    });
  }

  // Check for Collision between Bird and Barriers
  void _checkCollision() {
    // Define bird dimensions
    double birdWidth = 50; // Adjust based on your MyBird widget
    double birdHeight = 50; // Adjust based on your MyBird widget

    // Define barrier dimensions
    double barrierWidth = 100; // Adjust based on your MyBarrier widget
    double barrierGap = 150; // Gap between top and bottom barriers

    // Function to convert alignment to actual position
    double alignmentToPosition(double alignment, bool isVertical, double size) {
      if (isVertical) {
        return (alignment + 1) * (MediaQuery.of(context).size.height / 2) -
            size / 2;
      } else {
        return (alignment + 1) * (MediaQuery.of(context).size.width / 2) -
            size / 2;
      }
    }

    // Bird position
    double birdXPos = alignmentToPosition(0, false, birdWidth);
    double birdYPos = alignmentToPosition(birdYaxis, true, birdHeight);

    // Barrier One Positions
    double barrierOneXPos =
        alignmentToPosition(barrierXone, false, barrierWidth);
    double barrierOneTopY = alignmentToPosition(-1.1, true, 0);
    double barrierOneBottomY = alignmentToPosition(1.1, true, 0) - barrierGap;

    // Barrier Two Positions
    double barrierTwoXPos =
        alignmentToPosition(barrierXtwo, false, barrierWidth);
    double barrierTwoTopY = alignmentToPosition(-1.1, true, 0);
    double barrierTwoBottomY = alignmentToPosition(1.1, true, 0) - barrierGap;

    // Check collision with Barrier One
    bool collisionWithBarrierOne = (birdXPos < barrierOneXPos + barrierWidth &&
            birdXPos + birdWidth > barrierOneXPos) &&
        (birdYPos < barrierOneTopY + barrierGap ||
            birdYPos + birdHeight > barrierOneBottomY);

    // Check collision with Barrier Two
    bool collisionWithBarrierTwo = (birdXPos < barrierTwoXPos + barrierWidth &&
            birdXPos + birdWidth > barrierTwoXPos) &&
        (birdYPos < barrierTwoTopY + barrierGap ||
            birdYPos + birdHeight > barrierTwoBottomY);

    if (collisionWithBarrierOne || collisionWithBarrierTwo) {
      gameTimer?.cancel();
      gameHasStarted = false;
      _showGameOverDialog();
    }
  }

  // Show Game Over Dialog
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dialog from closing on tap outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Game Over!",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          content: Text(
            "Your Score: $score",
            style: TextStyle(color: Colors.black54, fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: Text(
                "Restart",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (gameHasStarted) {
          jump();
        } else {
          startGame();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  AnimatedContainer(
                    alignment: Alignment(0, birdYaxis),
                    color: Colors.blue,
                    duration: Duration(milliseconds: 0),
                    child: MyBird(),
                  ),
                  Container(
                    alignment: Alignment(0, -0.4),
                    child: gameHasStarted
                        ? Text(" ")
                        : Text(
                            "T A P  T O  P L A Y",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                  // Barrier One - Bottom
                  AnimatedContainer(
                    alignment: Alignment(barrierXone, 1.1),
                    duration: Duration(milliseconds: 0),
                    child: MyBarrier(
                      size: 200.0,
                    ),
                  ),
                  // Barrier One - Top
                  AnimatedContainer(
                    alignment: Alignment(barrierXone, -1.1),
                    duration: Duration(milliseconds: 0),
                    child: MyBarrier(
                      size: 200.0,
                    ),
                  ),
                  // Barrier Two - Bottom
                  AnimatedContainer(
                    alignment: Alignment(barrierXtwo, 1.1),
                    duration: Duration(milliseconds: 0),
                    child: MyBarrier(
                      size: 150.0,
                    ),
                  ),
                  // Barrier Two - Top
                  AnimatedContainer(
                    alignment: Alignment(barrierXtwo, -1.1),
                    duration: Duration(milliseconds: 0),
                    child: MyBarrier(
                      size: 250.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 15,
              color: Colors.green,
            ),
            Expanded(
              child: Container(
                color: Colors.brown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Current Score
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "SCORE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "$score",
                          style: TextStyle(color: Colors.white, fontSize: 22),
                        ),
                      ],
                    ),
                    // Best Score
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "BEST SCORE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "$bestScore",
                          style: TextStyle(color: Colors.white, fontSize: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
