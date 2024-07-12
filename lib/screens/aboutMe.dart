import 'package:flutter/material.dart';

class AboutMePg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Me'),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://i.pinimg.com/originals/ab/4b/0f/ab4b0f549fba20a4c786353f02a27411.jpg'),
                fit: BoxFit
                    .cover, // You can use BoxFit.contain or BoxFit.fill depending on your preference
              ),
            ),
          ),
          // Content with semi-transparent background
          Container(
            color: Colors.black.withOpacity(0.3), // Adjust the opacity here
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Hey there! 🌟',
                      style: TextStyle(
                          fontSize: 28.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      'I\'m the developer behind this awesome App. I truly hope it becomes your perfect study buddy, helping you ace those study sessions! 📚✨ Let\'s make learning fun and productive together! 😊🚀',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.0),
                    Text(
                      'I created this app using Flutter, starting on May 1, 2024. If you have any suggestions or encounter any issues, feel free to email me at myattheingimin3532@gmail.com. Your feedback is always welcome! 😊✨',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.0),
                    Text(
                      'Thank you for using my app! I\'ve worked really hard on it and hope it helps you in your studies. 🙏❤️',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
