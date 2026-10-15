import 'package:flutter/material.dart';

import 'drawing_canvas.dart';
import 'nib_model.dart';

void main() {
  runApp(const FountainPenPrototypeApp());
}

class FountainPenPrototypeApp extends StatelessWidget {
  const FountainPenPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fountain Pen Nib Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF14213D),
        scaffoldBackgroundColor: const Color(0xFFF6F3EC),
      ),
      home: const NibPrototypeScreen(),
    );
  }
}

class NibPrototypeScreen extends StatefulWidget {
  const NibPrototypeScreen({super.key});

  @override
  State<NibPrototypeScreen> createState() => _NibPrototypeScreenState();
}

class _NibPrototypeScreenState extends State<NibPrototypeScreen> {
  final NibModel _nibModel = NibModel();
  final GlobalKey<DrawingCanvasState> _canvasKey =
      GlobalKey<DrawingCanvasState>();

  bool _showDebugOverlay = false;

  void _clearCanvas() {
    _canvasKey.currentState?.clearStrokes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fountain Pen Nib Prototype'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: DrawingCanvas(
                key: _canvasKey,
                nibModel: _nibModel,
                showDebugOverlay: _showDebugOverlay,
              ),
            ),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSliderRow(
            label: 'Thin Width',
            value: _nibModel.thinWidth,
            min: 0.5,
            max: 20,
            onChanged: (v) => setState(() => _nibModel.thinWidth = v),
          ),
          _buildSliderRow(
            label: 'Thick Width',
            value: _nibModel.thickWidth,
            min: 1,
            max: 40,
            onChanged: (v) => setState(() => _nibModel.thickWidth = v),
          ),
          _buildSliderRow(
            label: 'Nib Angle',
            value: _nibModel.nibAngle,
            min: 0,
            max: 180,
            suffix: '\u00b0',
            onChanged: (v) => setState(() => _nibModel.nibAngle = v),
          ),
          _buildSliderRow(
            label: 'Smoothing',
            value: _nibModel.smoothing,
            min: 0,
            max: 0.95,
            onChanged: (v) => setState(() => _nibModel.smoothing = v),
          ),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Debug Overlay'),
                    Switch(
                      value: _showDebugOverlay,
                      onChanged: (v) => setState(() => _showDebugOverlay = v),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _clearCanvas,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Canvas'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    String suffix = '',
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '${value.toStringAsFixed(1)}$suffix',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}