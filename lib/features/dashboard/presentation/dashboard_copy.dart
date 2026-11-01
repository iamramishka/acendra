/// Shared dashboard copy, including accessibility labels.
abstract final class DashboardCopy {
  static const brand = 'Acedra';
  static const searchCourses = 'Search courses';
  static const home = 'Home';
  static const myLearning = 'My Learning';
  static const explore = 'Explore';
  static const myCourses = 'My Courses';
  static const saved = 'Saved';
  static const profile = 'Profile';
  static const savedComingSoon = 'Saved courses are coming soon.';
  static const savedExplanation =
      'Saving courses is not available yet. Explore the marketplace to find courses.';
  static const exploreCourses = 'Explore Courses';
  static const categories = 'Explore Categories';
  static const featured = 'Latest Courses';
  static const whyLearn = 'Why Learn with Acedra?';
  static const viewAll = 'View All';
  static const noCategories = 'Categories will appear here when available.';
  static const noCourses = 'Published courses will appear here when available.';
  static const noHighlights = 'Learning highlights will appear here soon.';
  static const noSlides = 'Explore courses and discover your next skill.';
  static const previousSlide = 'Previous slide';
  static const nextSlide = 'Next slide';
  static const pauseSlides = 'Pause automatic slides';
  static const resumeSlides = 'Resume automatic slides';
  static const loading = 'Loading course discovery';
  static const loadError = 'Unable to load course discovery. Please try again.';
  static const retry = 'Retry';
  static String slide(int index, int total) => 'Slide $index of $total';
  static String openCourse(String title) => 'View course: $title';
}
