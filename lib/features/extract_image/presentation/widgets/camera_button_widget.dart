import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/widgets/custom_button.dart';
import 'package:qrscanner/features/extract_image/presentation/cubit/extract_image_cubit.dart';
import 'package:qrscanner/features/extract_image/presentation/cubit/extract_image_state.dart';

class CameraButtonWidget extends StatelessWidget {
  const CameraButtonWidget({required this.onPress, super.key});
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<ExtractImageCubit, ExtractImageState, bool>(
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
