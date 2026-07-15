import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/past_rides_view.dart';
import '../widgets/upcoming_rides_view.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Rides'),
          centerTitle: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Past'),
              Tab(text: 'Upcoming'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: const TabBarView(
          children: [
            _PastTab(),
            _UpcomingTab(),
          ],
        ),
      ),
    );
  }
}

class _PastTab extends StatelessWidget {
  const _PastTab();

  @override
  Widget build(BuildContext context) {
    return const PastRidesView();
  }
}

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context) {
    return const UpcomingRidesView();
  }
}
