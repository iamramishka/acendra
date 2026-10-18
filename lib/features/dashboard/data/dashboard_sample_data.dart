import 'package:acendra/features/dashboard/domain/entities/dashboard_category.dart';
import 'package:acendra/features/dashboard/domain/entities/hero_slide.dart';
import 'package:acendra/features/dashboard/domain/entities/why_learn_item.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';

// Offline preview fixtures only. IDs do not identify backend records and must
// not be used to open real course details, checkout, or grant course access.
// No application routing dependency is needed for the existing public path.
const sampleHeroSlides = <HeroSlide>[
  HeroSlide(
    id: 'welcome',
    label: 'WELCOME TO ACEDRA',
    headline: 'Learn with purpose. Grow with confidence.',
    subtext: 'Explore new subjects and take the next step in your learning.',
    ctaLabel: 'Explore Courses',
    ctaRoute: '/marketplace',
  ),
  HeroSlide(
    id: 'build-skills',
    label: 'EXPLORE YOUR INTERESTS',
    headline: 'Make room for your next skill.',
    subtext: 'Discover development, design, business, and language courses.',
    ctaLabel: 'Browse Courses',
    ctaRoute: '/marketplace',
  ),
  HeroSlide(
    id: 'start-learning',
    label: 'TAKE THE NEXT STEP',
    headline: 'Find a course that inspires you.',
    subtext: 'Choose a subject and start building your learning journey.',
    ctaLabel: 'Find a Course',
    ctaRoute: '/marketplace',
  ),
];

const sampleCategories = <DashboardCategory>[
  DashboardCategory(
    id: 'd0000000-0000-4000-8000-000000000001',
    name: 'Development',
    slug: 'development',
    icon: DashboardCategoryIcon.development,
  ),
  DashboardCategory(
    id: 'd0000000-0000-4000-8000-000000000002',
    name: 'Design',
    slug: 'design',
    icon: DashboardCategoryIcon.design,
  ),
  DashboardCategory(
    id: 'd0000000-0000-4000-8000-000000000003',
    name: 'Business',
    slug: 'business',
    icon: DashboardCategoryIcon.business,
  ),
  DashboardCategory(
    id: 'd0000000-0000-4000-8000-000000000004',
    name: 'Languages',
    slug: 'languages',
    icon: DashboardCategoryIcon.languages,
  ),
];

const sampleCourses = <CourseSummary>[
  CourseSummary(
    id: 'e0000000-0000-4000-8000-000000000001',
    slug: 'demo-flutter-foundations',
    title: 'Flutter Foundations (Demo)',
    shortDescription: 'Sample course: explore widgets and responsive layouts.',
    priceMinor: 450000,
    currencyCode: 'LKR',
    publishedAt: '2026-10-01T00:00:00Z',
    categoryId: 'd0000000-0000-4000-8000-000000000001',
  ),
  CourseSummary(
    id: 'e0000000-0000-4000-8000-000000000002',
    slug: 'demo-design-essentials',
    title: 'Design Essentials (Demo)',
    shortDescription: 'Sample course: discover layout, typography, and color.',
    priceMinor: 350000,
    currencyCode: 'LKR',
    publishedAt: '2026-10-02T00:00:00Z',
    categoryId: 'd0000000-0000-4000-8000-000000000002',
  ),
  CourseSummary(
    id: 'e0000000-0000-4000-8000-000000000003',
    slug: 'demo-business-basics',
    title: 'Business Basics (Demo)',
    shortDescription: 'Sample course: explore planning and business ideas.',
    priceMinor: 300000,
    currencyCode: 'LKR',
    publishedAt: '2026-10-03T00:00:00Z',
    categoryId: 'd0000000-0000-4000-8000-000000000003',
  ),
  CourseSummary(
    id: 'e0000000-0000-4000-8000-000000000004',
    slug: 'demo-everyday-english',
    title: 'Everyday English (Demo)',
    shortDescription: 'Sample course: practice everyday communication skills.',
    priceMinor: 250000,
    currencyCode: 'LKR',
    publishedAt: '2026-10-04T00:00:00Z',
    categoryId: 'd0000000-0000-4000-8000-000000000004',
  ),
];

const sampleWhyLearnItems = <WhyLearnItem>[
  WhyLearnItem(
    id: 'flexible-learning',
    title: 'Learn at your pace',
    subtitle: 'Make learning part of your own schedule.',
    icon: WhyLearnIcon.flexibleLearning,
  ),
  WhyLearnItem(
    id: 'practical-skills',
    title: 'Explore practical skills',
    subtitle: 'Find subjects connected to your interests and goals.',
    icon: WhyLearnIcon.practicalSkills,
  ),
  WhyLearnItem(
    id: 'learning-materials',
    title: 'Explore learning materials',
    subtitle: 'Discover courses with lessons and supporting resources.',
    icon: WhyLearnIcon.learningMaterials,
  ),
  WhyLearnItem(
    id: 'progress',
    title: 'Continue your journey',
    subtitle: 'Return to your learning and take the next step.',
    icon: WhyLearnIcon.progress,
  ),
];
