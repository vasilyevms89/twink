import 'package:flutter/material.dart';
import 'package:twink/presentation/effectstab.dart';
import 'package:twink/presentation/settingstab.dart';
import 'package:provider/provider.dart';
import 'package:twink/services/udp_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UdpService(),
      child: const Body(),
    ),
  );
}

class Body extends StatelessWidget {
  const Body({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GyverTwink Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('GyverTwink Manager'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.home), text: 'Настройки'),
                Tab(icon: Icon(Icons.settings), text: 'Настройки эффекта'),
                Tab(icon: Icon(Icons.camera), text: 'Калибровка'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              Center(child: SKSettingsTab()),
              Center(child: EffectsTab()),
              Center(child: Text('Содержимое третьего окна')),
            ],
          ),
        ),
      ),
    );
  }
}
