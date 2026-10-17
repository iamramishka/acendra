/// Shared dashboard copy, including accessibility labels.
abstract final class DashboardCopy {
  static const categories = 'Explore Categories';
  static const featured = 'Featured Courses';
  static const whyLearn = 'Why Learn with Acedra?';
  static const viewAll = 'View All';
  static const noCategories = 'Categories will appear here when available.';
  static const noCourses = 'Featured courses will appear here when available.';
  static const noHighlights = 'Learning highlights will appear here soon.';
  static const noSlides = 'Explore courses and discover your next skill.';
  static const previousSlide = 'Previous slide';
  static const nextSlide = 'Next slide';
  static const pauseSlides = 'Pause automatic slides';
  static const resumeSlides = 'Resume automatic slides';
  static const loading = 'Loading student home';
  static const loadError = 'Unable to load student home. Please try again.';
  static const retry = 'Retry';
  static const previewNotice =
      'Dashboard preview: courses and categories below are sample content.';
  static const previewCategory =
      'This is a sample category. Explore the marketplace for available courses.';
  static const previewCourse =
      'This is a demo course. Explore the marketplace for available courses.';
  static String slide(int index, int total) => 'Slide $index of $total';
  static String openCourse(String title) => 'View course: $title';
}
