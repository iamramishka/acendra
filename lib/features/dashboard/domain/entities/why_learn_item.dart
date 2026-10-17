/// Semantic icon keys resolved by dashboard widgets.
enum WhyLearnIcon {
  flexibleLearning,
  practicalSkills,
  learningMaterials,
  progress,
}

class WhyLearnItem {
  const WhyLearnItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final WhyLearnIcon icon;
}
