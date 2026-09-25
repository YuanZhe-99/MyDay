import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../services/bank_preset_service.dart';

/// A bank preset's logo: bundled asset first, network preview second, `fallback` last.
class BankLogoImage extends StatefulWidget {
  final BankPreset bank;
  final double size;
  final Widget fallback;

  /// Purpose: Create a bank logo view.
  /// Inputs: `bank`, `size` (square edge, default 32), `fallback` (shown when nothing loads).
  /// Returns: A new `BankLogoImage` instance.
  /// Side effects: None.
  /// Notes: Used by the bank preset picker; saved account logos use `StoredImage` instead.
  const BankLogoImage({
    super.key,
    required this.bank,
    required this.fallback,
    this.size = 32,
  });

  /// Purpose: Create the state that loads the bundled asset once.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: None.
  /// Notes: None.
  @override
  State<BankLogoImage> createState() => _BankLogoImageState();
}

class _BankLogoImageState extends State<BankLogoImage> {
  Future<ByteData?>? _asset;

  /// Purpose: Start loading the bundled asset, if this build lists one.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Starts an asset-bundle read.
  /// Notes: Loading the bytes here (instead of `SvgPicture.asset`) turns a listed-but-missing
  /// asset into a null result, so the tile degrades to the network preview quietly.
  @override
  void initState() {
    super.initState();
    _asset = _load(widget.bank.bundledLogoAsset);
  }

  /// Purpose: Reload when the tile is reused for a different preset.
  /// Inputs: `oldWidget`.
  /// Returns: None.
  /// Side effects: May start a new asset-bundle read.
  /// Notes: List tiles are recycled while scrolling or searching.
  @override
  void didUpdateWidget(BankLogoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bank.key != widget.bank.key) {
      _asset = _load(widget.bank.bundledLogoAsset);
    }
  }

  /// Purpose: Load an asset's bytes, mapping every failure to null.
  /// Inputs: `key` (null when no bundled logo).
  /// Returns: `Future<ByteData?>?` — null future when there is nothing to load.
  /// Side effects: Reads the asset bundle.
  /// Notes: Internal helper used within this file only.
  static Future<ByteData?>? _load(String? key) {
    if (key == null) return null;
    return rootBundle.load(key).then<ByteData?>((d) => d, onError: (_) => null);
  }

  /// Purpose: Build the network preview, or the fallback when there is no domain.
  /// Inputs: None.
  /// Returns: `Widget`.
  /// Side effects: `Image.network` fetches the Clearbit preview.
  /// Notes: The pre-1.4.5 picker behavior, kept as the second tier.
  Widget _network() {
    final url = widget.bank.logoUrl;
    if (url.isEmpty) return widget.fallback;
    return Image.network(
      url,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => widget.fallback,
    );
  }

  /// Purpose: Build the bundled logo, the network preview, or the fallback.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: None beyond the loads described above.
  /// Notes: SVGs render with `contain` on white so wordmarks stay whole in dark mode.
  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    if (asset == null) return _network();
    return FutureBuilder<ByteData?>(
      future: asset,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(width: widget.size, height: widget.size);
        }
        final data = snap.data;
        if (data == null) return _network();
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        final isSvg = widget.bank.bundledLogoAsset!.toLowerCase().endsWith(
          '.svg',
        );
        return Container(
          width: widget.size,
          height: widget.size,
          color: Colors.white,
          padding: EdgeInsets.all(widget.size * 0.12),
          child: isSvg
              ? SvgPicture.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _network(),
                )
              : Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _network(),
                ),
        );
      },
    );
  }
}
