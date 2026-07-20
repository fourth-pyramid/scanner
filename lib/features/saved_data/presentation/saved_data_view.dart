import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/core/widgets/custom_text_field.dart';
import 'package:qrscanner/features/saved_data/component/saved_data_card.dart';
import 'package:qrscanner/features/saved_data/domain/entities/saved_scan_entity.dart';
import 'package:qrscanner/features/saved_data/presentation/bloc/saved_data_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ponytail: view for saved scans with skeletonizer loader
class SavedDataView extends StatelessWidget {
  const SavedDataView({super.key});

  static final List<SavedScanEntity> _dummyScans = List.generate(
    5,
    (index) => SavedScanEntity(id: index, pin: '12345678901234', serial: '987654321098'),
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => GetIt.I<SavedDataBloc>()..add(const LoadScansEvent()),
    child: Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Text('Saved Scans', style: AppTextStyles.titleMedium),
        backgroundColor: colorSurface,
        foregroundColor: colorPrimary,
        centerTitle: true,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: colorDivider),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) =>
              BlocSelector<
                SavedDataBloc,
                SavedDataState,
                ({bool isLoading, List<SavedScanEntity> scans, bool hasError})
              >(
                selector: (state) => (
                  isLoading: state is SavedDataLoading,
                  scans: context.read<SavedDataBloc>().scans,
                  hasError: state is SavedDataError,
                ),
                builder: (context, data) {
                  if (data.hasError) {
                    return const _EmptyOrErrorState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Connection Error',
                      message: 'Unable to load saved scans.\nPlease try again later.',
                      isError: true,
                    );
                  }

                  if (data.scans.isEmpty && !data.isLoading) {
                    return const SingleChildScrollView(
                      child: _EmptyOrErrorState(
                        icon: Icons.inbox_outlined,
                        title: 'No Scans Found',
                        message: "You don't have any scans matching this search, or you haven't scanned anything yet.",
                      ),
                    );
                  }

                  final displayScans = data.isLoading ? _dummyScans : data.scans;

                  return Column(
                    children: [
                      // ─── Stats Bar ───
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: colorSurface,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: colorBorder, width: 1.2.r),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: colorPrimary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.list_alt_rounded, size: 16.r, color: colorPrimary),
                                    SizedBox(width: 6.w),
                                    Text(
                                      data.isLoading ? '... Records' : '${data.scans.length} Records',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: colorPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  _ActionChip(label: 'Excel', icon: Icons.table_chart_outlined, onTap: () {}),
                                  SizedBox(width: 8.w),
                                  _ActionChip(label: 'Email', icon: Icons.email_outlined, onTap: () {}),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─── Search ───
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
                        child: CustomTextField(
                          hint: 'Search by PIN or serial…',
                          prefixIcon: Icon(Icons.search_rounded, size: 20.r),
                          onChanged: (value) {
                            context.read<SavedDataBloc>().add(SearchScansEvent(value));
                          },
                        ),
                      ),

                      // ─── List / Skeletonizer ───
                      Expanded(
                        child: Skeletonizer(
                          enabled: data.isLoading,
                          ignoreContainers: true,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
                            physics: const BouncingScrollPhysics(),
                            itemCount: displayScans.length,
                            itemBuilder: (context, index) => SavedDataCard(savedData: displayScans[index]),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    ),
  );
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(color: colorPrimary, borderRadius: BorderRadius.circular(20.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: Colors.white),
          SizedBox(width: 5.w),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
        ],
      ),
    ),
  );
}

class _EmptyOrErrorState extends StatelessWidget {
  const _EmptyOrErrorState({required this.icon, required this.title, required this.message, this.isError = false});
  final IconData icon;
  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? colorError : colorTextSecondary;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(color: color.withAlpha(18), shape: BoxShape.circle),
              child: Icon(icon, size: 48.r, color: color),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(color: colorTextPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
