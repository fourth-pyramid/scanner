import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:qrscanner/core/router/router.dart';
import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/features/card_type/domain/entities/category_entity.dart';
import 'package:qrscanner/features/card_type/presentation/bloc/card_type_bloc.dart';
import 'package:qrscanner/features/extract_image/presentation/bloc/extract_image_bloc.dart';
import 'package:qrscanner/features/extract_image/presentation/pages/extract_image_page.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ponytail: view for selecting a scan card type with skeleton loading
class CardTypeView extends StatelessWidget {
  const CardTypeView({super.key});

  static const List<String> _fallbackImages = [
    'assets/images/20.jpeg',
    'assets/images/25.jpeg',
    'assets/images/30.jpeg',
    'assets/images/50.jpeg',
    'assets/images/100.jpeg',
  ];

  static final List<CategoryEntity> _dummyCategories = List.generate(
    6,
    (index) => CategoryEntity(id: index, name: 'Loading Card...', image: 'assets/images/20.jpeg'),
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => GetIt.I<CardTypeBloc>()..add(const GetCategoriesEvent()),
    child: Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Text('Select Card Type', style: AppTextStyles.titleMedium),
        backgroundColor: colorSurface,
        foregroundColor: colorPrimary,
        centerTitle: true,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: colorDivider),
        ),
      ),
      body: Builder(
        builder: (context) =>
            BlocSelector<
              CardTypeBloc,
              CardTypeState,
              ({bool isLoading, List<CategoryEntity> categories, bool hasError})
            >(
              selector: (state) => (
                isLoading: state is CardTypeLoading,
                categories: context.read<CardTypeBloc>().categories,
                hasError: state is CardTypeError,
              ),
              builder: (context, data) {
                if (data.hasError) {
                  return const _EmptyState(
                    icon: Icons.dashboard_outlined,
                    message: 'No card types available.\nPlease check your server connection.',
                  );
                }

                if (data.categories.isEmpty && !data.isLoading) {
                  return const _EmptyState(
                    icon: Icons.dashboard_outlined,
                    message: 'No card types available.\nPlease check your server connection.',
                  );
                }

                final displayCategories = data.isLoading ? _dummyCategories : data.categories;

                return Skeletonizer(
                  enabled: data.isLoading,
                  ignoreContainers: true,

                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(8.w, 20.h, 8.w, 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Types', style: AppTextStyles.titleSmall.copyWith(color: colorTextSecondary)),
                          SizedBox(height: 14.h),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 7.w,
                              mainAxisSpacing: 7.h,
                              childAspectRatio: 1.3,
                            ),
                            itemCount: displayCategories.length,
                            itemBuilder: (context, index) {
                              final item = displayCategories[index];
                              final fallbackImage = _fallbackImages[index % _fallbackImages.length];

                              return _CategoryCard(
                                fallbackImage: fallbackImage,
                                label: item.name ?? '',
                                onTap: data.isLoading
                                    ? () {} // ponytail: prevent click while loading
                                    : () async => await MagicRouter.navigateTo(
                                        BlocProvider(
                                          create: (context) =>
                                              GetIt.I<ExtractImageBloc>()..add(const LoadHistoryCountEvent()),
                                          child: ExtractImagePage(scanType: item.name ?? '', categoryId: item.id!),
                                        ),
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.fallbackImage, required this.label, required this.onTap});

  final String fallbackImage;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colorBorder, width: 1.2.r),
        boxShadow: [BoxShadow(color: colorPrimary.withAlpha(12), blurRadius: 10.r, offset: Offset(0, 4.h))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(fallbackImage, fit: BoxFit.fill),
            // Gradient overlay for label
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [colorPrimary.withAlpha(200), Colors.transparent],
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(40.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(color: colorPrimary.withAlpha(12), shape: BoxShape.circle),
            child: Icon(icon, size: 48.r, color: colorTextSecondary),
          ),
          SizedBox(height: 20.h),
          Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
