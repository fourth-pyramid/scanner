import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:qrscanner/core/di/injection_container.dart';
import 'package:qrscanner/core/router/router.dart';
import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/core/widgets/l10n_extension.dart';
import 'package:qrscanner/features/card_scanner/presentation/bloc/card_scanner_bloc.dart';
import 'package:qrscanner/features/card_scanner/presentation/widgets/action_card.dart';
import 'package:qrscanner/features/card_scanner/presentation/widgets/clear_data_card.dart';
import 'package:qrscanner/features/card_scanner/presentation/widgets/scanner_header.dart';
import 'package:qrscanner/features/card_type/presentation/card_type_view.dart';
import 'package:qrscanner/features/saved_data/presentation/saved_data_view.dart';

// ponytail: UI page for card scanner, clean architecture structure
class CardScannerPage extends StatelessWidget {
  const CardScannerPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<CardScannerBloc>(),
        child: const _CardScannerView(),
      );
}

class _CardScannerView extends StatelessWidget {
  const _CardScannerView();

  @override
  Widget build(BuildContext context) =>
      BlocListener<CardScannerBloc, CardScannerState>(
        listener: (context, state) {
          if (state is CardScannerLoading) {
            unawaited(showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(
                child: CircularProgressIndicator(color: colorPrimary),
              ),
            ));
          } else if (state is CardScannerSuccess) {
            // Pop loading dialog
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 20.r,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      context.l10n.allDataCleared,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                backgroundColor: colorSuccess,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                margin: EdgeInsets.all(16.r),
              ),
            );
          } else if (state is CardScannerError) {
            // Pop loading dialog
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorError,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: colorBackground,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── Header ───
                const SliverToBoxAdapter(
                  child: ScannerHeader(),
                ),

                // ─── Section Title ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 16.h),
                    child: Text(
                      context.l10n.quickActions,
                      style: AppTextStyles.titleSmall,
                    ),
                  ),
                ),

                // ─── Action Cards ───
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14.w,
                      mainAxisSpacing: 14.h,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildListDelegate([
                      ActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        label: context.l10n.scanCard,
                        description: context.l10n.startNewScan,
                        iconColor: colorPrimary,
                        iconBg: colorPrimary.withAlpha(18),
                        onTap: () =>
                            MagicRouter.navigateTo(const CardTypeView()),
                      ),
                      ActionCard(
                        icon: Icons.bookmarks_outlined,
                        label: context.l10n.savedScans,
                        description: context.l10n.viewHistory,
                        iconColor: colorAccent,
                        iconBg: colorAccent.withAlpha(22),
                        onTap: () =>
                            MagicRouter.navigateTo(const SavedDataView()),
                      ),
                    ]),
                  ),
                ),

                // ─── Danger Zone ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 16.h),
                    child: Text(
                      context.l10n.dataManagement,
                      style: AppTextStyles.titleSmall,
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 40.h),
                  sliver: const SliverToBoxAdapter(
                    child: ClearDataCard(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
