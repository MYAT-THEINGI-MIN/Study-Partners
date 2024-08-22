import 'package:flutter/material.dart';

class AboutMePg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.deepPurple,
              child: Text(
                '🎓',
                style: TextStyle(fontSize: 50),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hey there! 🌟',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'I’m the developer behind this awesome App. I truly hope it becomes your perfect study buddy, helping you ace those study sessions! 📚✨ Let’s make learning fun and productive together! 😊🚀',
              style: TextStyle(
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Special thanks to our supervisor Dr. Amy Aung for her help and advice! 🙏❤️',
              style: TextStyle(
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Our Team:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '• Myat Theingi Min\n• Ye Zaw Tun\n• Pyae Sone Phyo',
              style: TextStyle(
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'I created this app using Flutter, starting on May 1, 2024. If you have any suggestions or encounter any issues, feel free to email me at myattheingimin3532@gmail.com. Your feedback is always welcome! 😊✨',
              style: TextStyle(
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Thank you for using my app! I’ve worked really hard on it and hope it helps you in your studies.❤️',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
