import 'package:flutter/material.dart';
import 'package:twink/presentation/maintab.dart';

void main() {
  runApp(const Body());
}

class Body extends StatelessWidget {
  const Body({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twink',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Переключение окон'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.home), text: 'Окно 1'),
                Tab(icon: Icon(Icons.person), text: 'Окно 2'),
                Tab(icon: Icon(Icons.settings), text: 'Окно 3'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              Center(child: maintab() ),
              Center(child: Text('Содержимое второго окна')),
              Center(child: Text('Содержимое третьего окна')),
            ],
          ),
        ),
      ),
    );


  }
}


