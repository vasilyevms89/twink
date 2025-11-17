import 'package:flutter/material.dart';
import 'package:twink/presentation/calibrationtab.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GyverTwink Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      // Заменяем stateless Body на StatefulWidget с TabController
      home: const HomeScreen(),
    );
  }
}

// Новый StatefulWidget для управления TabController
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// Используем SingleTickerProviderStateMixin для контроллера вкладок
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Добавляем слушателя для отслеживания смены вкладок
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    // Проверяем, что индекс меняется и новая вкладка — это "Настройки" (индекс 0)
    if (_tabController.indexIsChanging && _tabController.index == 0) {
      final udpService = Provider.of<UdpService>(context, listen: false);

      // Если устройства уже были найдены ранее, отправляем запрос настроек
      if (udpService.found) {
        udpService.requestCfg();
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('GyverTwink Manager'),
        bottom: TabBar(
          controller: _tabController, // Передаем управляемый контроллер
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Настройки'),
            Tab(icon: Icon(Icons.settings), text: 'Эффекты'),
            Tab(icon: Icon(Icons.camera), text: 'Калибровка'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Передаем управляемый контроллер
        children: const [
          Center(child: SKSettingsTab()),
          Center(child: EffectsTab()),
          Center(child: CalibrationTab()),
        ],
      ),
    );
  }
}