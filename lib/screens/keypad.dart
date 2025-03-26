import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:june/june.dart';
import 'package:sumit/screens/keypad_button.dart';
import 'package:sumit/state/module.dart';
import 'package:sumit/utils.dart';
import 'package:sumit/utils/translations_extension.dart';

class Keypad extends StatefulWidget {
  const Keypad({super.key});

  @override
  State<Keypad> createState() => _KeypadState();
}

class _KeypadState extends State<Keypad> {
  DisplayState displayState = June.getState(() => DisplayState());

  Future<void> handleCheck() async {
    try {
      await displayState.handleAddRecord();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.translate('keypad.success')),
            backgroundColor: Colors.green.shade300,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        logger.e(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate('keypad.error', args: {'error': e.toString()}),
            ),
            backgroundColor: e is DisplayError ? e.color : Colors.red.shade300,
          ),
        );
      }
    } finally {
      displayState.resetDisplay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: StaggeredGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('7', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('7'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('8', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('8'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('9', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('9'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Icon(Icons.keyboard_backspace, size: 38),
              onPressed: () => displayState.handleBackspaceInput(),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('4', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('4'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('5', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('5'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('6', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('6'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('-/+', textScaler: TextScaler.linear(2)),
              onPressed:
                  () => displayState.handleOperatorInput(
                    displayState.operator.isEmpty ||
                            displayState.operator == "+"
                        ? "-"
                        : "+",
                  ),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('1', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('1'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('2', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('2'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('3', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('3'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 2,
            child: KeypadButton(
              primary: true,
              content: Icon(Icons.done, size: 38),
              onPressed: () => handleCheck(),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('0', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleNumberInput('0'),
            ),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: KeypadButton(
              content: Text('.', textScaler: TextScaler.linear(3)),
              onPressed: () => displayState.handleCommaInput(),
            ),
          ),
        ],
      ),
    );
  }
}
