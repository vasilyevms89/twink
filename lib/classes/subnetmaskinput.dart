import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:twink/classes/func.dart';


class IpAddressInput extends StatefulWidget {
  final String? initialValue;
  const IpAddressInput({super.key, this.initialValue});

  @override
  State<IpAddressInput> createState() => _IpAddressInputState();
}

class _IpAddressInputState extends State<IpAddressInput> {
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
    final mask = await loadSubNetMask();
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
          saveSubNetMask(_controller.text); // Сохранение при каждом изменении
        },
      ),
    );
  }
}