import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/widgets/custom_button.dart';
import 'package:qrscanner/features/extract_image/presentation/bloc/extract_image_bloc.dart';

class CameraButtonWidget extends StatelessWidget {
  const CameraButtonWidget({required this.onPress, super.key});
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<ExtractImageBloc, ExtractImageState, bool>(
        selector: (state) => state is Scanning,
        builder: (context, isScanning) => CustomButton(
          isIcon: !isScanning,
          icon: const Icon(
            Icons.camera_alt_outlined,
            color: Colors.white,
            size: 22,
          ),
          text: isScanning ? '' : 'Capture Card',
          isLoading: isScanning,
          onPress: onPress,
        ),
      );
}
