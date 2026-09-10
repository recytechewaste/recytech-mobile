import 'package:flutter/material.dart';

import '../../../data/repositories/points_rewards_repository.dart';
import '../../user/rewards/rewards_screen.dart';

class PartnerRewardsScreen extends StatelessWidget {
  const PartnerRewardsScreen({super.key, this.repository});

  final PointsRewardsRepository? repository;

  @override
  Widget build(BuildContext context) =>
      RewardsScreen.informational(repository: repository);
}
