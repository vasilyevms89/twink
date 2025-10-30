import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import 'package:twink/services/udp_service.dart';


class SubNetMaskInputWidget extends StatefulWidget {
  final String? initialValue;
  const SubNetMaskInputWidget({super.key, this.initialValue});

  @override
  State<SubNetMaskInputWidget> createState() => _SubNetMaskInputWidgetState();
}

class _SubNetMaskInputWidgetState extends State<SubNetMaskInputWidget> {
  late final TextEditingController _controller;

  final _maskFormatter = MaskTextInputFormatter(
    mask: '###.###.###.###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    // 2. Инициализация контроллера с начальным значением
    _controller = TextEditingController(text: widget.initialValue);
    _loadInitialData();

  }

  Future<void> _loadInitialData() async {
    final udpService = Provider.of<UdpService>(context, listen: false);
    final mask = await udpService.loadSubNetMask();
    // Проверяем, что виджет все еще смонтирован, прежде чем обновлять состояние
    if (mounted) {
      setState(() {
        _controller.text = mask;
      });
    }
  }


  @override
  void dispose() {
    // 3. Очистка контроллера при удалении виджета
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final udpService = Provider.of<UdpService>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Маска подсети',
          hintText: '255.255.255.0 - наиболее популярная маска',
        ),
        inputFormatters: [_maskFormatter],
        onChanged: (value) {
          udpService.saveSubNetMask(_controller.text);
        },
      ),
    );
  }
}